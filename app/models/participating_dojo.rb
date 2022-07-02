class ParticipatingDojo < ApplicationRecord
  audited

  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, -> { order index: :asc, lastname: :asc, firstname: :asc },
           dependent: :destroy,
           inverse_of: :participating_dojo do
            def unteamed
              where "team_id IS NULL"
            end
          end
  has_many :teams, -> { order index: :asc, shortname: :asc }, dependent: :destroy, inverse_of: :participating_dojo
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
          puts
          team.update!(index: index + count + 1)
        end
      end
    end
    true
  end

  def teams_by_score(final)
    @teams_by_score =
      teams
        .sort_by { |team| team.score(final) }.reverse
        .group_by { |team| team.score(final) }
        .each do |_, teams|
          teams.sort_by! { |team| [-team.tie_break_score(final), team.index] }
        end
  end
end
