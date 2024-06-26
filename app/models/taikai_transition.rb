class TaikaiTransition < ApplicationRecord
  validates :to_state, inclusion: { in: TaikaiStateMachine.states }
  # If your transition table doesn't have the default `updated_at` timestamp column,
  # you'll need to configure the `updated_timestamp_column` option, setting it to
  # another column name (e.g. `:updated_on`) or `nil`.
  #
  # self.updated_timestamp_column = :updated_on
  # self.updated_timestamp_column = nil

  belongs_to :taikai, inverse_of: :taikai_transitions

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = taikai.taikai_transitions.order(:sort_key).last
    return if last_transition.blank?

    last_transition.update_column(:most_recent, true)
  end
end
