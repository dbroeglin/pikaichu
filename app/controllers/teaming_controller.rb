class TeamingController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo

  def edit
    @teams = @participating_dojo.teams.includes(:participants).order("teams.shortname ASC")
    @participants = @participating_dojo.participants.where("participants.team_id IS NULL")
    @team = @participating_dojo.teams.build()
  end

  def create_team
    @team = @participating_dojo.teams.build(shortname: params[:shortname])

    @team.save

    if @team.errors.of_kind? :shortname, :taken
      flash[:alert] = t 'teaming.edit.taken_team_shortname', shortname: params[:shortname]
    elsif @team.errors.of_kind? :shortname, :blank
      flash[:alert] = t 'teaming.edit.empty_team_shortname'
    end

    # Always redirect to edit
    redirect_to action: :edit, status: :see_other
  end

  def move
    participant = @participating_dojo.participants.find(params[:participant_id])

    if params[:team_id]
      team = @participating_dojo.teams.find(params[:team_id])

      if participant.team
        participant.move_to_bottom
        Participant.acts_as_list_no_update do
          participant.team = team
          participant.index_in_team = nil
          participant.save!
        end
        participant.insert_at(params[:index].to_i)
      else
        participant.team = team
        participant.save!
        participant.insert_at(params[:index].to_i)
      end
    else
      participant.move_to_bottom
      Participant.acts_as_list_no_update do
        participant.team_id = nil
        participant.index_in_team = nil
        participant.save!
      end
    end
  end

  def clear
    @participating_dojo.participants.update_all(team_id: nil)

    redirect_to action: :edit, status: :see_other
  end

  def apply
    @teams = @participating_dojo.teams.includes(:participants).order("teams.shortname ASC")

    # @participating_dojo.participants.group_by(&:club)

    redirect_to action: :edit, status: :see_other
  end

  private

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:id])
  end
end
