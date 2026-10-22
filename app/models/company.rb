# == Schema Information
#
# Table name: companies
#
#  id                :integer          not null, primary key
#  city              :string
#  country           :string
#  description       :text
#  jobs_trusted_at   :datetime
#  name              :string           not null
#  slug              :string           not null
#  website           :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  personal_owner_id :integer
#
# Indexes
#
#  index_companies_on_name               (name) UNIQUE
#  index_companies_on_personal_owner_id  (personal_owner_id) UNIQUE
#  index_companies_on_slug               (slug) UNIQUE
#
# Foreign Keys
#
#  personal_owner_id  (personal_owner_id => users.id) ON DELETE => cascade
#
class Company < ::ResourceRecord
  # add concerns above.

  # add constants above.

  # add enums above.
  path_parameter :slug

  # add model configurations above.

  # Set on a personal posting space: an individual posting gigs or jobs as
  # themselves rather than as a company.
  belongs_to :personal_owner, class_name: "User", optional: true

  # add belongs_to associations above.

  # add has_one associations above.
  has_many :company_users, dependent: :destroy
  has_many :users, through: :company_users
  has_many :job_posts, class_name: "Hiring::JobPost", dependent: :destroy
  has_many :company_user_invites, class_name: "Invites::CompanyUserInvite", dependent: :destroy

  # add has_many associations above.

  # add attachments above.
  scope :associated_with_user, ->(user) { joins(:company_users).where(company_users: {user_id: user.id}) }
  scope :organizations, -> { where(personal_owner_id: nil) }

  # add scopes above.

  validates :name, presence: true
  validates :website, **WebUrl.validation
  validates :country, **World.country_validation
  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "may only contain lowercase letters, numbers and dashes"}
  # add validations above.

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }
  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  # Trusted once an admin approves the company's first job.
  def jobs_trusted? = jobs_trusted_at.present?

  def personal? = personal_owner_id.present?

  # The poster's developer profile, for personal posting spaces.
  def personal_profile = personal_owner&.developer_profile

  # Personal spaces show as the person; their name can change after setup.
  def display_name = personal_profile&.name || name

  def to_label = personal? ? "#{display_name} (personal)" : name

  # The personal posting space for a user with a developer profile, created on
  # first use. The user owns it like any company, so the company portal,
  # applicant board, first-post review and emails all work unchanged.
  def self.personal_for!(user)
    profile = user.developer_profile or raise ArgumentError, "A developer profile is needed to post as yourself"

    find_by(personal_owner: user) || transaction do
      create!(personal_owner: user, name: profile.name, slug: unique_personal_slug(profile.handle)).tap do |company|
        company.company_users.create!(user:, role: :owner)
      end
    end
  end

  def self.unique_personal_slug(handle)
    base = "#{handle}-personal"
    slug = base
    slug = "#{base}-#{SecureRandom.alphanumeric(4).downcase}" while exists?(slug:)
    slug
  end

  # add methods above. add private methods below.
end
