class Taikai < ApplicationRecord
  include HasRankable
  audited

  attr_accessor :current_user
  attribute :total_num_arrows, default: 12
  attribute :num_targets, default: 6
  attribute :tachi_size, default: 3
  attribute :distributed, default: false
  enum form: {
    individual: 'individual',
    team: 'team',
    '2in1': '2in1',
    matches: 'matches',
  }, _prefix: :form
  human_enum :form

  enum scoring: {
    kinteki: 'kinteki',
    enteki: 'enteki',
  }, _prefix: :scoring
  human_enum :scoring

  has_many :taikai_transitions, autosave: false, class_name: :TaikaiTransition, dependent: :destroy
  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: TaikaiTransition,
    initial_state: :new
  ]
  delegate :can_transition_to?,
    :current_state, :history, :last_transition, :last_transition_to,
    :transition_to!, :transition_to, :in_state?, to: :state_machine

  has_many :staffs, dependent: :destroy do
    def ordered
      joins(:role)
        .left_outer_joins(:participating_dojo)
        .order(
          Arel.sql("staff_roles.label->>#{ActiveRecord::Base.connection.quote(I18n.locale)} ASC"),
          'participating_dojos.display_name': :asc,
        )
    end
  end
  has_many :matches, dependent: :destroy, inverse_of: :taikai
  has_many :participating_dojos, -> { order display_name: :asc },
           dependent: :destroy,
           inverse_of: :taikai
  has_many :participants, through: :participating_dojos
  has_many :teams, through: :participating_dojos

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
    staffs.create!(user: self.current_user, role: StaffRole.find_by_code(:taikai_admin))
  end

  def num_arrows
    @num_arrows ||= 4
  end

  def num_rounds
    total_num_arrows / num_arrows
  end

  def taikai_admin?(user)
    staffs.joins(:role).where(user: user, 'role.code': :taikai_admin).any?
  end

  def dojo_admin?(user)
    staffs.joins(:role).where(user: user, 'role.code': :dojo_admin).any?
  end

  def finalized?
    !Result.joins(participant: :participating_dojo).where("participating_dojos.id": participating_dojos.pluck(:id)).where(final: false).any?
  end

  # Remove after better handling of tie_break
  def teams_by_score(final)
    @teams_by_score =
      participating_dojos
      .map(&:teams).flatten
      .sort_by { |team| team.score(final) }.reverse
      .group_by { |team| team.score(final) }
      .each do |_, teams|
        teams.sort_by! { |team| [-team.tie_break_score(final), team.index || 0] }
      end
  end

  def self.create_from_2in1(taikai_id, current_user, shortname_suffix, name_suffix, bracket_size)
    taikai = Taikai.includes(
      {
        participating_dojos: [
          { teams: { participants: :results } },
          { participants: [:results, :kyudojin] }
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
      form: 'matches',
      scoring: taikai.scoring,
      current_user: current_user,
    )

    unless taikai.finalized?
      new_taikai.errors.add(:base, :not_finalized)
      return new_taikai
    end

    unless new_taikai.save
      return new_taikai
    end

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
    taikai
      .teams_by_score(true).values.flatten
      .select{ |team| !team.mixed } # TODO: generate error if not enough teams
      .first(bracket_size)
      .each_with_index do |team, index|
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
          ).assign_team1(team1).assign_team2(team2).save!
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
          ).assign_team1(team1).assign_team2(team2).save!
        end
    end
    taikai.matches.create!(index: 1, level: 1)
    taikai.matches.create!(index: 2, level: 1)
  end

  def state_machine
    @state_machine ||= TaikaiStateMachine.new(self, transition_class: TaikaiTransition)
  end

  def number_of_dojos
    if !distributed && participating_dojos.count > 1
      errors.add(:distributed, :num_participating_dojos)
    end
  end
end