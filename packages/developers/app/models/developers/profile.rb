# == Schema Information
#
# Table name: developers_profiles
#
#  id                 :integer          not null, primary key
#  availability       :integer          default("open"), not null
#  bio                :text
#  city               :string
#  contact_email      :string
#  contact_visibility :integer          default("members"), not null
#  country            :string
#  first_name         :string           not null
#  github_url         :string
#  handle             :string           not null
#  headline           :string
#  linkedin_url       :string
#  name               :string           not null
#  open_to_relocation :boolean          default(FALSE), not null
#  other_names        :string
#  phone              :string
#  region             :string
#  remote_ok          :boolean          default(TRUE), not null
#  seniority          :integer
#  timezone           :string
#  visibility         :integer          default("members"), not null
#  website_url        :string
#  x_url              :string
#  years_experience   :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer          not null
#
# Indexes
#
#  index_developers_profiles_on_country                      (country)
#  index_developers_profiles_on_handle                       (handle) UNIQUE
#  index_developers_profiles_on_user_id                      (user_id) UNIQUE
#  index_developers_profiles_on_visibility_and_availability  (visibility,availability)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require_relative "../developers"

class Developers::Profile < Developers::ResourceRecord
  # add concerns above.

  HANDLE_FORMAT = /\A[a-z0-9][a-z0-9_-]{1,28}[a-z0-9]\z/
  RESERVED_HANDLES = %w[
    admin admins api company companies dashboard developer developers help jobs
    login logout manage onboarding projects settings setup signup support users welcome
  ].freeze

  # add constants above.

  enum :availability, {not_looking: 0, open: 1, looking: 2}
  enum :seniority, {junior: 0, mid: 1, senior: 2, lead: 3, principal: 4}
  # Who can find the profile (directory and /@handle). Hidden profiles are
  # only visible to their owner.
  enum :visibility, {hidden: 0, members: 1, everyone: 2}, prefix: :visible_to
  # Who may see contact_email and phone.
  enum :contact_visibility, {everyone: 0, members: 1, connections: 2}, prefix: :contact_visible_to

  # add enums above.

  path_parameter :handle

  # add model configurations above.

  belongs_to :user
  # add belongs_to associations above.

  # add has_one associations above.

  has_many :experiences, -> { order(started_on: :desc) }, class_name: "Developers::Experience", dependent: :destroy
  has_many :profile_skills, class_name: "Developers::ProfileSkill", dependent: :destroy
  has_many :skills, through: :profile_skills
  has_many :job_applications, class_name: "Hiring::JobApplication", dependent: :destroy

  # Network: follows in both directions. Two people who follow each other are
  # connected (see #connections).
  has_many :outgoing_follows, class_name: "Network::Follow", foreign_key: :follower_id, inverse_of: :follower, dependent: :delete_all
  has_many :incoming_follows, class_name: "Network::Follow", foreign_key: :followee_id, inverse_of: :followee, dependent: :delete_all
  has_many :following, through: :outgoing_follows, source: :followee
  has_many :followers, through: :incoming_follows, source: :follower
  has_many :given_endorsements, class_name: "Network::Endorsement", foreign_key: :endorser_id, inverse_of: :endorser, dependent: :destroy

  # Showcase: projects they own, and their credits on other people's projects.
  has_many :projects, class_name: "Showcase::Project", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :project_contributions, class_name: "Showcase::ProjectContributor", dependent: :delete_all

  # add has_many associations above.

  # add attachments above.

  # Profiles a viewer may see in the directory: public ones for guests, plus
  # members-only ones for signed-in users.
  scope :visible_to, ->(user) { user ? where(visibility: %i[members everyone]) : visible_to_everyone }

  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.strip.downcase)}%"
    left_joins(profile_skills: :skill).where(
      "LOWER(developers_profiles.name) LIKE :t OR developers_profiles.handle LIKE :t OR LOWER(developers_profiles.headline) LIKE :t " \
      "OR LOWER(developers_profiles.bio) LIKE :t OR LOWER(developers_profiles.city) LIKE :t OR LOWER(developers_profiles.country) LIKE :t " \
      "OR LOWER(skills.name) LIKE :t", t: term
    ).distinct
  }

  # add scopes above.

  validates :handle, presence: true, uniqueness: true,
    format: {with: HANDLE_FORMAT, message: "must be 3-30 lowercase letters, numbers, dashes or underscores"},
    exclusion: {in: RESERVED_HANDLES, message: "is reserved"}
  validates :user, uniqueness: {message: "already has a developer profile"}
  validates :website_url, :github_url, :linkedin_url, :x_url, **WebUrl.validation
  validates :contact_email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :years_experience, numericality: {only_integer: true, in: 0..60}, allow_nil: true
  validates :first_name, presence: true
  validates :country, **World.country_validation
  validates :remote_ok, inclusion: {in: [true, false]}
  validates :open_to_relocation, inclusion: {in: [true, false]}
  validates :availability, presence: true
  validates :visibility, presence: true
  validates :contact_visibility, presence: true
  # add validations above.

  normalizes :handle, with: ->(handle) { handle.strip.downcase.delete_prefix("@") }
  normalizes :first_name, :other_names, with: ->(name) { name.squish }

  before_validation { self.name = [first_name, other_names].compact_blank.join(" ") }

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    name
  end

  CompletenessItem = Data.define(:key, :label, :done)

  # Checklist shown on the dashboards to nudge people toward a useful profile.
  def completeness_items
    [
      CompletenessItem.new(:headline, "Add a headline", headline.present?),
      CompletenessItem.new(:bio, "Write a short bio", bio.present?),
      CompletenessItem.new(:location, "Say where you're based", country.present?),
      CompletenessItem.new(:links, "Link your GitHub, LinkedIn or website", [github_url, linkedin_url, website_url].any?(&:present?)),
      CompletenessItem.new(:skills, "Add at least 3 skills", profile_skills.size >= 3),
      CompletenessItem.new(:experience, "Add your experience", experiences.any?)
    ]
  end

  def completeness_percent
    items = completeness_items
    (items.count(&:done) * 100.0 / items.size).round
  end

  def visible_to?(user)
    return true if user && user_id == user.id
    return false if visible_to_hidden?

    visible_to_everyone? || user.present?
  end

  def contact_visible_to?(user)
    return true if user && user_id == user.id
    return true if contact_visible_to_everyone?
    return user.present? if contact_visible_to_members?

    connected_to?(user&.developer_profile)
  end

  # People this profile follows who follow it back.
  def connections
    following.where(id: incoming_follows.select(:follower_id))
  end

  def connected_to?(other)
    return false if other.nil? || other.id == id

    following?(other) && followed_by?(other)
  end

  def following?(other)
    other.present? && outgoing_follows.exists?(followee_id: other.id)
  end

  def followed_by?(other)
    other.present? && incoming_follows.exists?(follower_id: other.id)
  end

  # Followers this profile hasn't followed back yet.
  def unanswered_followers
    followers.where.not(id: outgoing_follows.select(:followee_id))
  end

  # "People you may know": people your connections follow, ranked by how many
  # of your connections follow them, then people who share your skills.
  # Hidden profiles and people you already follow are left out.
  def suggested_profiles(limit: 6)
    candidates = Developers::Profile.where.not(visibility: :hidden)
      .where.not(id: id).where.not(id: outgoing_follows.select(:followee_id))

    via_network = candidates.joins(:incoming_follows)
      .where(network_follows: {follower_id: connections.select(:id)})
      .group(:id).order(Arel.sql("COUNT(*) DESC"), updated_at: :desc).limit(limit).to_a
    return via_network if via_network.size >= limit

    shared_skills = candidates.where.not(id: via_network.map(&:id))
      .where(id: Developers::ProfileSkill.where(skill_id: profile_skills.select(:skill_id)).select(:profile_id))
      .order(updated_at: :desc).limit(limit - via_network.size)
    via_network + shared_skills.to_a
  end

  def location
    [city, region, country].compact_blank.join(", ")
  end

  # add methods above. add private methods below.
end
