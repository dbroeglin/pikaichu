# rubocop:disable Metrics/ClassLength

class ParticipantsController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo
  before_action :set_team
  before_action :set_parent_association

  def new
    @participant = @parent_association.build(
      index_in_team: (@parent_association.maximum(:index_in_team) || 0) + 1
    )
  end

  def create
    @participant = @parent_association.build(participant_params)
    @participant.participating_dojo = @participating_dojo if @team

    if @participant.kyudojin
      @participant.firstname = @participant.kyudojin.firstname
      @participant.lastname = @participant.kyudojin.lastname
    end

    if @participant.save && @participant.generate_empty_results
      redirect_to_edit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @participant = @parent_association.find(params[:id])
  end

  def update
    @participant = @parent_association.find(params[:id])

    @participant.assign_attributes(participant_params)
    if @participant.kyudojin
      @participant.firstname = @participant.kyudojin.firstname
      @participant.lastname = @participant.kyudojin.lastname
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
        skip_lines: /CNKyudo - Interface de gestion/
      ) do |row|
        attrs = {
          federation_country_code: 'FR',
          federation_club: row['Club'],
          firstname: I18n.transliterate(row['Prénom']).upcase,
          lastname: I18n.transliterate(row['Nom']).upcase,
        }
        kyudojin = Kyudojin.find_by(**attrs)

        @participant = @participating_dojo.participants.build(
          firstname: row['Prénom'],
          lastname: row['Nom'],
        )
        if kyudojin
          @participant.kyudojin = kyudojin
        else
          notices << "#{row['Prénom']} #{row['Nom']}"
        end

        if @participant.save
          @participant.generate_empty_results
        else
          alerts << "#{row['Prénom']} #{row['Nom']}"
        end
      end
      flash[:notice] = t :import_notices, names: notices.join(', '), count: notices.size
      flash[:alert] = t :import_alerts, names: alerts.join(', '), count: alerts.size
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
        :excel,
        :index,
        :index_in_team,
        :firstname,
        :lastname,
        :taikai_id,
        :participating_dojo_id,
        :team_id,
        :kyudojin_id
      )
  end

  def redirect_to_edit
    if @team
      redirect_to controller: 'teams', action: 'edit',
                  taikai_id: @taikai, participating_dojo: @participating_dojo, id: @team
    else
      redirect_to controller: 'participating_dojos', action: 'edit',
                  taikai_id: @taikai, id: @participating_dojo
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
