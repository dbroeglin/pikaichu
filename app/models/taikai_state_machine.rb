class TaikaiStateMachine
  include Statesman::Machine

  state :new, initial: true
  state :on_going
  state :validated

  transition from: :new,        to: :on_going
  transition from: :on_going,   to: :validated

  guard_transition to: :on_going do |taikai|
    # TODO: enough info for a dojo to start the taikai
    true
  end

  guard_transition to: :validated do |taikai|
    # all participating dojos validated
    taikai.participating_dojos.all? &:validated?
  end
end