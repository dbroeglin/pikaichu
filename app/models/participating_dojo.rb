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
    when '2in1'
      if participants.unteamed.any?
        errors.add(:base, :unteamed)
        return false
      else
        teams.update_all(index: nil)
        count = 0
        teams.select do |team|
          team.participants.size >= taikai.tachi_size
        end.shuffle.each_with_index do |team, index|
          team.update!(index: index + 1)
          count += 1
        end
        teams.where(index: nil).shuffle.each_with_index do |team, index|
          team.update!(index: index + count + 1)
        end
      end
    end
    true
  end

  def finalized?
    participants.all?(&:finalized?)
  end

  def in_state?(*params)
    #  Note: used by RankedAssociationExtension
    taikai.in_state?(*params)
  end

  def to_ascii
    [
      "Participating Dojo #{display_name} (#{id})",
      "  Participants: #{participants.count}",
      "  Teams: #{teams.count}",
    ].flatten.join "\n"
  end
end
