class Taikai < ApplicationRecord
  attribute :total_num_arrows, default: 12
  attribute :num_targets, default: 6
  attribute :tachi_size, default: 3
  enum form: {
    individual: 'individual',
    team: 'team',
    '2in1': '2in1'
  }, _prefix: :form

  audited

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
  has_many :participating_dojos, -> { order display_name: :asc },
           dependent: :destroy,
           inverse_of: :taikai
  has_many :participants, through: :participating_dojos

  validates :shortname,
            presence: true, length: { minimum: 3, maximum: 32 },
            uniqueness: { case_sensitive: false },
            format: { with: /\A(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)\z/ }

  validates :name, :start_date, :end_date, :form, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :total_num_arrows,
            presence: true,
            inclusion: {
              in: [12, 20]
            }
  validates :tachi_size,
            presence: true,
            inclusion: {
              in: [3, 5]
            }
  validates :num_targets,
            presence: true,
            inclusion: {
              in: [3, 6, 5, 10]
            }

  attr_accessor :current_user

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

  def self.create_from_2in1(taikai_id, current_user, shortname_suffix, name_suffix, bracket_size)
    taikai = Taikai.includes(
      {
        participating_dojos: [
          { teams: { participants: :results }},
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
      total_num_arrows: taikai.total_num_arrows,
      num_targets: taikai.num_targets,
      tachi_size: taikai.tachi_size,
      distributed: taikai.distributed,
      form: 'team',
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
    new_teams = {}
    taikai
      .participating_dojos
      .map(&:teams).flatten
      .sort_by(&:score).reverse
      .first(bracket_size)
      .each do |team|
        puts "Creating new team #{team.shortname}"
        new_team = new_participating_dojos[team.participating_dojo_id].teams.create!(
          shortname: team.shortname
          # TODO: index based on scoring of the current taikai
        )
        team.participants.each do |participant|
          puts "  Creating new participant #{participant.display_name}"
          new_team.participants.create!(
            kyudojin: participant.kyudojin,
            firstname: participant.firstname,
            lastname: participant.lastname,
            participating_dojo: new_participating_dojos[team.participating_dojo_id],
          )
        end
    end
    # TODO: create matches and .create_empty_results


    new_taikai
  end
end