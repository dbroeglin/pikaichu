class ParticipantsController < ApplicationController
  MAX_IMPORT_SIZE = 10.megabytes

  layout "taikai"

  before_action :set_taikai
  before_action :set_participating_dojo
  before_action :authorize_participating_dojo
  before_action :set_team
  before_action :set_parent_association
  after_action :verify_authorized

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
    upload = params[:excel]

    if valid_excel_upload?(upload)
      xlsx = Roo::Excelx.new(upload.tempfile.path)
      csv_data = xlsx.sheet(0).to_csv

      notices = []
      alerts = []
      CSV.parse(
        csv_data,
        headers: true,
        col_sep: ",",
        skip_lines: /Kyudo - Interface de gestion/
      ) do |row|
        attrs = {
          federation_country_code: "FR",
          federation_club: row["Club"],
          firstname: I18n.transliterate(row["Prénom"]).upcase.tr("-", " "),
          lastname: I18n.transliterate(row["Nom"]).upcase.tr("-", " ")
        }
        kyudojin = Kyudojin.find_by(**attrs)

        @participant = @participating_dojo.participants.build(
          firstname: row["Prénom"],
          lastname: row["Nom"],
          club: row["Club"]
        )
        if kyudojin
          @participant.kyudojin = kyudojin
        else
          notices << "#{row['Prénom']} #{row['Nom']}"
        end

        alerts << "#{row['Prénom']} #{row['Nom']}" unless @participant.save
      end
      flash[:notice] = t :import_notices, names: notices.join(", "), count: notices.size if notices.any?
      flash[:alert] = t :import_alerts, names: alerts.join(", "), count: alerts.size if alerts.any?
    elsif upload.blank?
      flash[:alert] = t :file_missing
    else
      flash[:alert] = t :invalid_file
    end
    redirect_to_edit
  rescue CSV::MalformedCSVError, Nokogiri::XML::SyntaxError, Roo::Error, Zip::Error => error
    logger.warn "Rejected invalid participant import: #{error.class}: #{error.message}"
    flash[:alert] = t :invalid_file
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

  def authorize_participating_dojo
    authorize @participating_dojo, :update?
  end

  def set_team
    @team = @participating_dojo.teams.find(params[:team_id]) if params[:team_id]
  end

  def set_parent_association
    @parent_association = @team ? @team.participants : @participating_dojo.participants
  end

  def valid_excel_upload?(upload)
    upload.is_a?(ActionDispatch::Http::UploadedFile) &&
      File.extname(upload.original_filename.to_s).casecmp?(".xlsx") &&
      upload.size <= MAX_IMPORT_SIZE &&
      xlsx_signature?(upload)
  end

  def xlsx_signature?(upload)
    upload.tempfile.rewind
    upload.tempfile.read(4) == "PK\x03\x04".b
  ensure
    upload.tempfile.rewind
  end
end
