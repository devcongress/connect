# == Schema Information
#
# Table name: developers_profile_skills
#
#  id                 :integer          not null, primary key
#  endorsements_count :integer          default(0), not null
#  level              :integer
#  years              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  profile_id         :integer          not null
#  skill_id           :integer          not null
#
# Indexes
#
#  index_developers_profile_skills_on_profile_id               (profile_id)
#  index_developers_profile_skills_on_skill_id_and_profile_id  (skill_id,profile_id) UNIQUE
#
# Foreign Keys
#
#  profile_id  (profile_id => developers_profiles.id)
#  skill_id    (skill_id => skills.id)
#
require_relative "../developers"

class Developers::ProfileSkill < Developers::ResourceRecord
  # add concerns above.

  # add constants above.

  enum :level, {beginner: 0, intermediate: 1, advanced: 2, expert: 3}

  # add enums above.

  # add model configurations above.

  belongs_to :profile, class_name: "Developers::Profile"
  belongs_to :skill
  # add belongs_to associations above.

  # add has_one associations above.

  has_many :experience_skills, class_name: "Developers::ExperienceSkill", inverse_of: :profile_skill, dependent: :delete_all
  has_many :experiences, through: :experience_skills
  has_many :endorsements, class_name: "Network::Endorsement", dependent: :delete_all
  has_many :endorsers, through: :endorsements
  # add has_many associations above.

  # add attachments above.

  # endorsers also points at Developers::Profile, so name the owning one.
  scope :associated_with_developers_profile, ->(profile) { where(profile:) }
  # add scopes above.

  validates :skill, uniqueness: {scope: :profile_id, message: "is already on this profile"}
  validates :years, numericality: {only_integer: true, in: 0..60}, allow_nil: true
  # add validations above.

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    skill&.name
  end

  # add methods above. add private methods below.
end
