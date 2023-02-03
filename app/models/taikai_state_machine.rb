class TaikaiStateMachine
  include Statesman::Machine

  state :new, initial: true # Initial state; Taikai structure change possible
  state :registration       # Registration phase; Adding participants & teams
  state :marking            # Marking phase; Marking the scores
  state :tie_break          # Tie Break phase; All markings are validated, tie-break may happen
  state :done               # Done; Taikai is done and cannot be modified anymore

  transition from: :new,          to: :registration
  transition from: :registration, to: :new
  transition from: :registration, to: :marking
  transition from: :marking,      to: :registration
  transition from: :marking,      to: :tie_break
  transition from: :tie_break,    to: :done

  guard_transition to: :marking do |taikai|
    # TODO: enough info for a dojo to start the taikai
    true
  end

  before_transition(from: :registration, to: :marking) do |taikai, transition|
    taikai.create_scores unless taikai.form_matches?
  end

  before_transition(from: :marking, to: :registration) do |taikai, transition|
    taikai.delete_scores unless taikai.form_matches?
  end

  before_transition(from: :marking, to: :tie_break) do |taikai, transition|
    Leaderboard.new(taikai_id: taikai.id, validated: true).compute_intermediate_ranks
  end


  guard_transition to: :tie_break do |taikai|
    # all participating dojos validated
    #taikai.participating_dojos.all?(&:finalized?)
    true
  end
end