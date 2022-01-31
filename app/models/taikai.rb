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
end