class TaikaiStateMachine
  include Statesman::Machine

  state :new, initial: true       # Initial state; Taikai structure change possible
  state :registration             # Registration phase; Adding participants & teams
  state :marking                  # Marking phase; Marking the scores
  state :tie_break                # Tie Break phase; All markings are validated, tie-break may happen
  state :done                     # Done; Taikai is done and cannot be modified anymore

  # "Forward" transitions

  transition from: :new,          to: :registration
  transition from: :registration, to: :marking
  transition from: :marking,      to: :tie_break
  transition from: :tie_break,    to: :done

  # "Backward" transitions

  transition from: :registration, to: :new
  transition from: :marking,      to: :registration

  # TODO: delete after manual tests ?
  transition from: :tie_break,    to: :marking
  transition from: :done,         to: :tie_break

  # Guards

  guard_transition from: :registration, to: :marking do |taikai|
    taikai.staffs.map { |staff| staff.role.code }.uniq.select do |role_code|
      %w[chairman shajo_referee target_referee ].include? role_code
    end.size == 3
  end

  guard_transition from: :marking, to: :tie_break do |taikai|
    # all participating dojos have finalized results
    taikai.participating_dojos.all?(&:finalized?)
  end

  # All transitions call-backs

  before_transition do |taikai, transition|
    TaikaiEvent.state_transition(
      user: taikai.current_user,
      taikai: taikai,
      from: taikai.current_state,
      to: transition.to_state)
  end

  # "Forward" transitions call-backs

  before_transition(from: :registration, to: :marking) do |taikai, transition|
    taikai.create_scores unless taikai.form_matches? if taikai.id > 74 # TODO: remove after migration
  end

  before_transition(from: :marking, to: :registration) do |taikai, transition|
    taikai.delete_scores unless taikai.form_matches? if taikai.id > 74 # TODO: remove after migration
  end

  # "Backward" transitions call-backs

  before_transition(from: :marking, to: :tie_break) do |taikai, transition|
    Leaderboard.new(taikai_id: taikai.id, validated: true).compute_intermediate_ranks
  end

  before_transition(from: :tie_break, to: :marking) do |taikai, transition|
    taikai.participants.clear_ranks
    taikai.teams.clear_ranks
  end
end