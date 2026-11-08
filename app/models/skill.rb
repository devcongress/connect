# == Schema Information
#
# Table name: skills
#
#  id               :integer          not null, primary key
#  category         :string
#  company_examples :json             not null
#  content_curated  :boolean          default(FALSE), not null
#  description      :text
#  name             :string           not null
#  slug             :string           not null
#  source_url       :string
#  website_url      :string
#  why_description  :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_skills_on_category         (category)
#  index_skills_on_content_curated  (content_curated)
#  index_skills_on_name             (name) UNIQUE
#  index_skills_on_slug             (slug) UNIQUE
#
class Skill < ::ResourceRecord
  # add concerns above.

  # add constants above.

  # add enums above.

  path_parameter :slug

  # add model configurations above.

  # add belongs_to associations above.

  # add has_one associations above.

  has_many :profile_skills, class_name: "Developers::ProfileSkill", dependent: :restrict_with_error
  has_many :project_skills, class_name: "Showcase::ProjectSkill", dependent: :restrict_with_error
  has_many :company_technologies, dependent: :restrict_with_error
  has_many :companies, through: :company_technologies
  # add has_many associations above.

  # add attachments above.

  scope :with_curated_content, -> { where(content_curated: true) }
  # add scopes above.

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :slug, presence: true
  validates :category, inclusion: {in: SkillDescription.categories}, allow_blank: true
  validates :website_url, :source_url, **WebUrl.validation
  validate :company_examples_are_linked_references
  validate :curated_content_is_complete
  # add validations above.

  normalizes :name, with: ->(name) { name.squish }
  normalizes :category, with: ->(category) { category.squish }
  normalizes :description, with: ->(description) { description.squish }
  normalizes :why_description, with: ->(description) { description.squish }
  before_validation { self.slug = self.class.slug_for(name) if slug.blank? }

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    name
  end

  def canonical_description
    description.presence || SkillDescription.description_for(name:, category:)
  end

  def canonical_why_description
    why_description.presence || SkillDescription.why_for(name:, category:)
  end

  # Keeps C, C++ and C# (and .NET vs NET) apart: "c", "c-plus-plus", "c-sharp", "dot-net".
  def self.slug_for(name)
    name.to_s.gsub("+", " plus ").gsub("#", " sharp ").sub(/\A\./, "dot ").parameterize
  end

  # add methods above. add private methods below.

  private

  def company_examples_are_linked_references
    valid = company_examples.is_a?(Array) && company_examples.all? do |example|
      example.is_a?(Hash) && example.values_at("name", "url").all?(&:present?) && example["url"].match?(WebUrl::FORMAT)
    end
    errors.add(:company_examples, "must include a name and http(s) source link for each company") unless valid
  end

  def curated_content_is_complete
    return unless content_curated?

    missing = %w[description website_url why_description].select { |attribute| public_send(attribute).blank? }
    missing << "company_examples" if company_examples.blank?
    errors.add(:content_curated, "requires description, website, why it matters and company references") if missing.any?
  end
end
