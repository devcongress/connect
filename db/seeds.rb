# Idempotent: safe to run on every deploy (bin/rails db:seed).

# Skills for profiles and project stacks. See db/seeds/skills.yml for where the
# list comes from. The catalogue is the source of truth for names and categories;
# skill_descriptions.yml adds precise copy where category-level copy is too broad.
catalogue = SkillDescription.catalogue
descriptions = YAML.load_file(Rails.root.join("db/seeds/skill_descriptions.yml"))
now = Time.current
skills = catalogue.flat_map do |category, content|
  content.fetch("skills").map do |name|
    slug = Skill.slug_for(name)
    curated = descriptions.fetch(slug, {})
    {
      name:,
      slug:,
      category:,
      description: curated["description"] || SkillDescription.description_for(name:, category:),
      website_url: curated["website_url"],
      source_url: curated["source_url"],
      why_description: curated["why_description"] || SkillDescription.why_for(name:, category:),
      company_examples: curated.fetch("company_examples", []),
      content_curated: curated.present?,
      created_at: now,
      updated_at: now
    }
  end
end
existing = Skill.where(slug: skills.pluck(:slug)).index_by(&:slug)
content_attributes = %w[name category description website_url source_url why_description company_examples content_curated]
changed = skills.select do |attributes|
  skill = existing[attributes[:slug]]
  skill.nil? || skill.attributes.values_at(*content_attributes) != attributes.values_at(*content_attributes.map(&:to_sym))
end
if changed.any?
  Skill.upsert_all(changed, unique_by: :index_skills_on_slug,
    update_only: %i[name category description website_url source_url why_description company_examples content_curated updated_at])
end

# The first DevCongress credential. Definitions live in the database so later
# achievements can be added without changing the issuance or verification flow.
Credentials::Definition.find_or_initialize_by(slug: "community-contributor").tap do |definition|
  definition.assign_attributes(
    name: "DevCongress Community Contributor",
    short_description: "Recognizes a reviewed, accepted contribution that materially advanced a DevCongress program, event, project, or community resource.",
    description: "The DevCongress Community Contributor credential recognizes someone whose completed contribution created clear value for the DevCongress community. It is awarded only after an authorized DevCongress administrator reviews evidence of the work against the published criteria.",
    eligibility_criteria: "The recipient must have completed at least one contribution accepted by the responsible DevCongress program, event, or project lead. The contribution must have a concrete outcome that benefited the community, and the recipient's role must be supported by first-party evidence rather than self-report alone.",
    evidence_requirements: "A reviewer must record a concise account of the contribution and retain or reference first-party evidence such as a merged contribution, published resource, organizer record, program deliverable, or written confirmation from the responsible lead.",
    issuing_authority: "DevCongress",
    approver_roles: %w[super_admin admin],
    criteria_version: "1.0",
    lifecycle_rules: "This credential does not expire. DevCongress may correct factual errors, revoke a credential when evidence is invalidated or misconduct materially undermines the award, and reissue it when a correction requires a new credential ID. Every lifecycle action requires a reason and remains in the audit trail.",
    does_not_prove: "This credential does not represent employment by DevCongress, an academic degree, professional licensure, identity verification, or endorsement by LinkedIn. It verifies only the reviewed DevCongress contribution described on this page.",
    badge_alt_text: "DevCongress Community Contributor credential badge",
    expires_after_months: nil,
    active: true
  )
  definition.save!
end
