# rubocop:disable Metrics/ClassLength

class ParticipantsController < ApplicationController
  layout 'taikai'

  before_action :set_taikai
  before_action :set_participating_dojo
  before_action :set_team
  before_action :set_parent_association

  def new
    @participant = @parent_association.build(
      index_in_team: (@parent_association.maximum(:index_in_team) || 0) + 1
    )
  end

  def edit
    @participant = @parent_association.find(params[:id])
  end

  def create
    @participant = @parent_association.build(participant_params)
    @participant.participating_dojo = @participating_dojo if @team

    if @participant.kyudojin
      @participant.firstname = @participant.kyudojin.firstname
      @participant.lastname = @participant.kyudojin.lastname
      @participant.club = @participant.kyudojin.federation_club
    end

    if @participant.save
      redirect_to_edit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @participant = @parent_association.find(params[:id])

    @participant.assign_attributes(participant_params)
    if @participant.kyudojin
      @participant.firstname = @participant.kyudojin.firstname
      @participant.lastname = @participant.kyudojin.lastname
      @participant.club = @participant.kyudojin.federation_club
    end

    if @participant.save
      redirect_to_edit
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @participant = @parent_association.find(params[:id])

    @participant.destroy
    redirect_to_edit
  end

  def reorder
    @participant = @parent_association.find(params[:id])

    @participant.insert_at(params[:index].to_i)

    head :ok
  end

  def import
    if params[:excel]
      # TODO: minimal file validation here
      xlsx = Roo::Spreadsheet.open(params[:excel])
      csv_data = xlsx.sheet(0).to_csv

      notices = []
      alerts = []
      CSV.parse(
        csv_data,
        headers: true,
        col_sep: ',',
        skip_lines: /Kyudo - Interface de gestion/
      ) do |row|
        attrs = {
          federation_country_code: 'FR',
          federation_club: row['Club'],
          firstname: I18n.transliterate(row['Prénom']).upcase.tr('-', ' '),
          lastname: I18n.transliterate(row['Nom']).upcase.tr('-', ' '),
        }
        kyudojin = Kyudojin.find_by(**attrs)

        @participant = @participating_dojo.participants.build(
          firstname: row['Prénom'],
          lastname: row['Nom'],
          club: row['Club']
        )
        if kyudojin
          @participant.kyudojin = kyudojin
        else
          notices << "#{row['Prénom']} #{row['Nom']}"
        end

        if @participant.save
          @participant.create_empty_score_and_results
        else
          alerts << "#{row['Prénom']} #{row['Nom']}"
        end
      end
      flash[:notice] = t :import_notices, names: notices.join(', '), count: notices.size if notices.any?
      flash[:alert] = t :import_alerts, names: alerts.join(', '), count: alerts.size if alerts.any?
    else
      flash[:alert] = t :file_missing
    end
    redirect_to_edit
  end

  private

  def participant_params
    params
      .require(:participant)
      .permit(
        :index,
        :firstname,
        :lastname,
        :club,
        :participating_dojo_id,
        :team_id,
        :kyudojin_id
      )
  end

  def redirect_to_edit
    if @team
      redirect_to edit_taikai_participating_dojo_team_path(@taikai, @participating_dojo, @team),
                  status: :see_other
    else
      redirect_to edit_taikai_participating_dojo_path(@taikai, @participating_dojo),
                  status: :see_other
    end
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end

  def set_team
    @team = @participating_dojo.teams.find(params[:team_id]) if params[:team_id]
  end

  def set_parent_association
    @parent_association = @team ? @team.participants : @participating_dojo.participants
  end
end
