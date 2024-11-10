class ParticipatingDojo < ApplicationRecord
  include ValidateChangeBasedOnState
  audited

  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, lambda {
                            order index: :asc, lastname: :asc, firstname: :asc
                          },
           extend: RankedAssociationExtension,
           dependent: :destroy,
           inverse_of: :participating_dojo do
    def unteamed
      where "team_id IS NULL"
    end
  end
  has_many :teams, lambda {
                     order index: :asc, shortname: :asc
                   },
           extend: RankedAssociationExtension,
           dependent: :destroy,
           inverse_of: :participating_dojo
  has_many :staffs, inverse_of: :participating_dojo, dependent: nil
  has_many :tachis, lambda {
                      order round: :asc, index: :asc
                    },
           inverse_of: :participating_dojo,
           dependent: :destroy

  def draw
    case taikai.form
    when 'individual'
      participants.update_all(index: nil)
      participants.shuffle.each_with_index do |participant, index|
        participant.update!(index: index + 1)
      end
    when 'team'
      teams.update_all(index: nil)
      teams.shuffle.each_with_index do |team, index|
        team.update!(index: index + 1)
      end
      teams.reload
      set_participant_index_from_teams
    when '2in1'
      if participants.unteamed.any?
        errors.add(:base, :unteamed)
        return false
      else
        teams.update_all(index: nil)
        count = 0
        teams.select { |team| team.participants.size >= taikai.tachi_size }
             .shuffle
             .each_with_index do |team, index|
               team.update!(index: index + 1)
               count += 1
             end
        teams.where(index: nil).shuffle.each_with_index do |team, index|
          team.update!(index: index + count + 1)
        end
        teams.reload
        set_participant_index_from_teams
      end
    end
    true
  end

  def drawn?
    case taikai.form
    when 'individual'
      participants.all? { |participant| participant.index.present? }
    when 'team', '2in1'
      teams.all? { |team| team.index.present? }
    when 'matches'
      true # For matches we do not need to draw, returning true
    end
  end

  def finalized?
    participants.all?(&:finalized?)
  end

  def in_state?(*params)
    #  Note: used by RankedAssociationExtension
    taikai.in_state?(*params)
  end

  def current_tachi
    tachis.where(finished: false).first
  end

  def create_tachis
    case taikai.form
    when 'individual', 'team', '2in1'
      taikai.num_rounds.times do |round|
        tachi_groups.each_with_index do |_, index|
          Tachi.create!(participating_dojo: self, round: round + 1, index: index + 1)
        end
      end
    when 'matches'
      raise 'Cannot create tachis for matches Taikais'
    end
  end

  def tachi_groups
    participants.draw_ordered.in_groups_of(taikai.num_targets)
  end

  def delete_tachis
    tachis.destroy_all
  end

  def update_tachi(score, round)
    tachi = get_tachi_by_participant_and_round(score.participant, round)
    tachi.participants.all? do |participants|
      participants.score(score.match_id).round_finalized?(tachi.round)
    end && tachi.update!(finished: true)
  end

  def get_tachi_by_participant_and_round(participant, round)
    tachi_groups.each_with_index do |group, index|
      return tachis.where(round: round, index: index + 1).first if group.include?(participant)
    end
    raise "Tachi not found for participant #{participant.id} and round #{round}"
  end

  def to_ascii
    [
      "Participating Dojo #{display_name} (#{id})",
      "  Participants: #{participants.count}",
      "  Teams: #{teams.count}",
    ].flatten.join "\n"
  end

  private

  def set_participant_index_from_teams
    participants.update_all(index: nil)
    teams.map(&:participants).flatten.each_with_index do |participant, index|
      participant.update!(index: index + 1)
    end
  end
end
