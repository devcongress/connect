# Idempotent: safe to run on every deploy (bin/rails db:seed).

# Skills for profiles, project stacks and company technologies. See db/seeds/skills.yml for where the
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
