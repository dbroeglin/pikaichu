class TeamingController < ApplicationController
  layout 'taikai'

  before_action :set_taikai
  before_action :set_participating_dojo

  def edit
    @teams = @participating_dojo.teams.includes(:participants).order("teams.shortname ASC")
    @participants = @participating_dojo.participants.unteamed.reorder(club: :asc, lastname: :asc, firstname: :asc)
    @team = @participating_dojo.teams.build
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
      else
        participant.team = team
        participant.save!
      end
      participant.insert_at(params[:index].to_i)
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

  def form_randomly
    if params[:prefix].blank?
      flash[:alert] = t 'teaming.edit.empty_team_prefix', shortname: params[:shortname]
    else
      unteamed_participants = @participating_dojo.participants.unteamed.shuffle
      groups = unteamed_participants.in_groups_of @participating_dojo.taikai.tachi_size

      groups.each_with_index do |group, index|
        team = @participating_dojo.teams.build(
          shortname: "#{params[:prefix]}#{index + 1}",
          mixed: true
        )

        group.compact.each_with_index do |participant, index|
          participant.index_in_team = index + 1
          team.participants << participant
        end

        team.save!
      end
    end
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
