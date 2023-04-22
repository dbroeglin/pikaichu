module ValidateChangeBasedOnState
  extend ActiveSupport::Concern

  included do
    validate :no_change_if_taikai_is_done, on: :update
    validate :no_change_if_taikai_is_marking, on: :update

    def no_change_if_taikai_is_done
      return unless changed? && self.taikai.in_state?('done')

      errors.add(:base, :no_change_if_taikai_is_done)
    end

    def no_change_if_taikai_is_marking
      case self
      when Participant, ParticipatingDojo, Taikai, Team
        if changed? &&
           # Rank changes for Participant and Teams are allowed due to tie-breaks
           !changes.keys.one? { |k| k == 'rank' } &&

           # We do not check in 'done' because it is immutable at that point
           !self.taikai.in_state?('new', 'registration', 'done')

          errors.add(:base, :no_change_if_taikai_is_marking)
        end
      end
    end
  end

  class_methods do
  end
end