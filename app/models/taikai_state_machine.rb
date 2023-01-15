class TaikaiStateMachine
  include Statesman::Machine

  state :new, initial: true
  state :registration
  state :marking
  state :validated

  transition from: :new,          to: :registration
  transition from: :registration, to: :marking
  transition from: :marking,      to: :registration
  transition from: :marking,      to: :validated

  guard_transition to: :marking do |taikai|
    # TODO: enough info for a dojo to start the taikai
    true
  end

  before_transition(from: :registration, to: :marking) do |taikai, transition|
    taikai.create_scores
  end

  before_transition(from: :marking, to: :registration) do |taikai, transition|
    taikai.delete_scores
  end


  guard_transition to: :validated do |taikai|
    # all participating dojos validated
    taikai.participating_dojos.all?(&:validated?)
  end
end