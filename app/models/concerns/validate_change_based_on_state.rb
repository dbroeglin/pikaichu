module ValidateChangeBasedOnState
  extend ActiveSupport::Concern

  included do
    validate :no_change_if_taikai_is_done, on: :update
    validate :no_change_if_taikai_is_marking, on: :update

    def no_change_if_taikai_is_done
      if changed? && self.taikai.in_state?('done')
        errors.add(:base, :no_change_if_taikai_is_done)
      end
    end

    def no_change_if_taikai_is_marking
      case self
      when Participant, ParticipatingDojo, Taikai, Team
        if changed? && !self.taikai.in_state?('new', 'registration', 'done')
          # We do not check in 'done' because it is immutable at that point
          errors.add(:base, :no_change_if_taikai_is_marking)
        end
      end
  end
  end

  class_methods do
  end
end