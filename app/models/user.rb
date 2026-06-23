# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("member"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  COMMUNITY_ROLES = %w[member].freeze
  ACCLINATE_ROLES = %w[employee admin super_admin].freeze
  ROLES = COMMUNITY_ROLES + ACCLINATE_ROLES

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_one :profile, dependent: :destroy
  has_many :saved_trials, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true
  validates :role, presence: true, inclusion: {in: ROLES}

  before_create :add_default_profile

  scope :acclinate, -> { where(role: ACCLINATE_ROLES) }
  scope :community, -> { where(role: COMMUNITY_ROLES) }
  scope :members, -> { where(role: "member") }
  scope :employees, -> { where(role: "employee") }
  scope :admins, -> { where(role: "admin") }
  scope :super_admins, -> { where(role: "super_admin") }

  def super_admin?
    role.eql?("super_admin")
  end

  def admin?
    role.eql?("admin")
  end

  def employee?
    role.eql?("employee")
  end

  def member?
    role.eql?("member")
  end

  def acclinate?
    super_admin? || admin? || employee?
  end

  private

  def add_default_profile
    self.profile ||= Profile.new
  end
end
