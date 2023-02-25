module NoChangeIfTaikaiDone
  extend ActiveSupport::Concern

  included do
    validate :no_change_if_taikai_is_done, on: :update

    def no_change_if_taikai_is_done
      if changed? && self.taikai.in_state?('done')
        errors.add(:base, :no_change_if_taikai_is_done)
      end
    end
  end

  class_methods do
  end
end