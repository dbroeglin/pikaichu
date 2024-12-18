class Taikai < ApplicationRecord
  include ValidateChangeBasedOnState
  audited

  # Used to pass the current user to the model logic (statesman or model methods)
  attr_accessor :current_user

  attribute :total_num_arrows, default: 12
  attribute :num_targets, default: 6
  attribute :tachi_size, default: 3
  attribute :distributed, default: false

  CATEGORY_VALUES = %w[A B C D].freeze

  enum :form, {
    individual: 'individual',
    team: 'team',
    '2in1': '2in1',
    matches: 'matches',
  }, prefix: :form
  human_enum :form

  enum :scoring, {
    kinteki: 'kinteki',
    enteki: 'enteki',
  }, prefix: :scoring
  human_enum :scoring

  has_many :taikai_transitions, autosave: false, class_name: :TaikaiTransition, dependent: :destroy
  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: TaikaiTransition,
    initial_state: :new
  ]
  delegate :can_transition_to?,
           :current_state, :history, :last_transition, :last_transition_to,
           :transition_to!, :transition_to, :in_state?, :allowed_transitions, to: :state_machine

  has_many :staffs, dependent: :destroy do
    def ordered
      joins(:role)
        .left_outer_joins(:participating_dojo)
        .order(
          Arel.sql("staff_roles.label->>#{ActiveRecord::Base.connection.quote(I18n.locale)} ASC"),
          'participating_dojos.display_name': :asc,
        )
    end

    def with_role(role)
      joins(:role)
        .where("staff_roles.code = ?", role)
    end
  end
  has_many :matches, dependent: :destroy, inverse_of: :taikai
  has_many :participating_dojos, -> { order display_name: :asc },
           dependent: :destroy,
           inverse_of: :taikai

  has_many :participants,
           extend: RankedAssociationExtension,
           through: :participating_dojos
  has_many :teams,
           extend: RankedAssociationExtension,
           through: :participating_dojos
  has_many :events,
           -> { order created_at: :asc },
           class_name: 'TaikaiEvent',
           inverse_of: :taikai,
           dependent: :destroy

  validates :category, inclusion: { in: CATEGORY_VALUES, allow_blank: true }
  validates :shortname,
            presence: true, length: { minimum: 3, maximum: 32 },
            uniqueness: { case_sensitive: false },
            format: { with: /\A(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)\z/ }

  validates :name, presence: true
  validates :form, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  validates :total_num_arrows, presence: true
  validates :total_num_arrows,
            inclusion: {
              in: [8, 12, 20]
            },
            if: -> { scoring_kinteki? && !form_matches? }
  validates :total_num_arrows,
            inclusion: {
              in: [4]
            },
            if: :form_matches?

  validates :tachi_size,
            presence: true,
            inclusion: {
              in: [3, 5]
            }
  validates :num_targets,
            presence: true,
            inclusion: {
              in: [3, 6, 5, 9, 10]
            }
  validate :number_of_dojos

  after_create do
    throw "current_user must be set at creation time" unless self.current_user
    staffs.create!(user: self.current_user, role: StaffRole.find_by!(code: :taikai_admin))
  end

  def num_arrows
    @num_arrows ||= 4
  end

  def num_rounds
    total_num_arrows / num_arrows
  end

  def roles?(user, roles)
    staffs.joins(:role).where(user: user, 'role.code': roles).any?
  end

  def finalized?
    Result
      .joins(score: { participant: :participating_dojo })
      .where("participating_dojos.id": participating_dojos.pluck(:id))
      .where(final: false).none?
  end

  def create_tachi_and_scores
    participating_dojos.each(&:create_tachis)
    if form_matches?
      matches.each(&:build_empty_score_and_results)
    else
      teams.each(&:build_empty_score)
      participants.each(&:build_empty_score_and_results)
    end
    save!
  end

  def delete_tachis_and_scores
    participating_dojos.each(&:delete_tachis)
    participants.each do |participant|
      participant.scores.destroy_all
    end
    teams.each do |team|
      team.scores.destroy_all
    end
    return unless form_matches?

    matches.each do |match|
      match.update!(winner: nil)
    end
  end

  def self.create_from_2in1(taikai_id, current_user, shortname_suffix, name_suffix, bracket_size)
    logger.info "Creating new '#{name_suffix}' Taikai from 2in1 Taikai #{taikai_id} with suffix #{shortname_suffix}"

    taikai = Taikai.includes(
      {
        participating_dojos: [
          { teams: :participants },
          { participants: :kyudojin }
        ]
      },
      staffs: :user
    ).find(taikai_id)

    new_taikai = Taikai.new(
      shortname: "#{taikai.shortname}-#{shortname_suffix}",
      name: "#{taikai.name} #{name_suffix}",
      start_date: taikai.start_date,
      end_date: taikai.end_date,
      total_num_arrows: 4,
      num_targets: taikai.num_targets,
      tachi_size: taikai.tachi_size,
      distributed: taikai.distributed,
      category: taikai.category,
      form: 'matches',
      scoring: taikai.scoring,
      current_user: current_user,
    )

    unless taikai.finalized?
      new_taikai.errors.add(:base, :not_finalized)
      return new_taikai
    end

    old_teams = taikai.teams.ranked(true).values.flatten
    if old_teams.size < bracket_size
      new_taikai.errors.add(:base, :not_enough_teams, bracket_size: bracket_size)
      return new_taikai
    end

    old_teams = old_teams.reject(&:mixed).take(bracket_size)
    if old_teams.size < bracket_size
      new_taikai.errors.add(:base, :not_enough_non_mixed_teams_html,
                            bracket_size: bracket_size,
                            old_teams_size: old_teams.size)
      return new_taikai
    end

    return new_taikai unless new_taikai.save

    taikai.staffs.each do |staff|
      next if current_user == staff.user && staff.role.taikai_admin?

      new_taikai.staffs.create!(
        role: staff.role,
        firstname: staff.firstname,
        lastname: staff.lastname,
        user: staff.user,
        participating_dojo: staff.participating_dojo,
      )
    end

    new_participating_dojos = {}
    taikai.participating_dojos.each do |participating_dojo|
      new_participating_dojos[participating_dojo.id] = new_taikai.participating_dojos.create!(
        display_name: participating_dojo.display_name,
        dojo: participating_dojo.dojo,
      )
    end

    # TODO: select only the 4/8 best teams to copy
    new_teams = []
    old_teams.each_with_index do |team, index|
      logger.info "Creating new team #{team.shortname}"
      new_team = new_participating_dojos[team.participating_dojo_id].teams.create!(
        shortname: team.shortname,
        index: index + 1
        # TODO: index based on scoring of the current taikai
      )
      new_teams << new_team
      team.participants.each do |participant|
        logger.info "  Creating new participant #{participant.display_name}"
        new_team.participants.create!(
          kyudojin: participant.kyudojin,
          firstname: participant.firstname,
          lastname: participant.lastname,
          club: participant.club,
          participating_dojo: new_participating_dojos[team.participating_dojo_id],
        )
      end
    end
    create_matches(new_taikai, new_teams)

    new_taikai
  end

  def self.create_matches(taikai, teams)
    num_teams = teams.size
    raise "Only 4 or 8 teams are allowed not #{num_teams}" if num_teams != 4 && num_teams != 8

    case num_teams
    when 8
      # re-order according to tournament guide version of Nov. 2021
      [teams[0], teams[7], teams[4], teams[3], teams[2], teams[5], teams[6], teams[1]]
        .in_groups_of(2)
        .each_with_index do |(team1, team2), index|
          taikai.matches.create!(
            index: index + 1,
            level: 3,
            team1: team1,
            team2: team2
          ).save!
        end
      taikai.matches.create!(index: 1, level: 2)
      taikai.matches.create!(index: 2, level: 2)
    when 4
      # assign according to tournament guide version of Nov. 2021
      [teams[0], teams[3], teams[2], teams[1]]
        .in_groups_of(2)
        .each_with_index do |(team1, team2), index|
          taikai.matches.create!(
            index: index + 1,
            level: 2,
            team1: team1,
            team2: team2
          ).save!
        end
    end
    taikai.matches.create!(index: 1, level: 1)
    taikai.matches.create!(index: 2, level: 1)
  end

  def state_machine
    @state_machine ||= TaikaiStateMachine.new(self, transition_class: TaikaiTransition)
  end

  def number_of_dojos
    return unless !distributed && participating_dojos.count > 1

    errors.add(:distributed, :num_participating_dojos)
  end

  def previous_state
    previous_index = TaikaiStateMachine.states.index(current_state.to_s) - 1
    TaikaiStateMachine.states[previous_index] if previous_index >= 0
  end

  def next_state
    next_state = TaikaiStateMachine.states.index(current_state.to_s) + 1
    TaikaiStateMachine.states[next_state] if next_state <= TaikaiStateMachine.states.size
  end

  def to_ascii
    [
      "Taikai #{shortname} (#id)",
      participating_dojos.map { |participating_dojo| participating_dojo.to_ascii.gsub(/^/, "  ") },
      "Staff:",
      staffs.map { |staff| staff.to_ascii.gsub(/^/, "  ") },
    ].flatten.join "\n"
  end

  private

  # Used by ValidateChangeBasedOnState concern
  def taikai
    self
  end
end
