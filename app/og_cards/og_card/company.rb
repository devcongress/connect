module OgCard
  class Company < Base
    def initialize(company)
      @company = company
    end

    def eyebrow = "Company"

    def title = @company.display_name

    def subtitle = @company.tagline.presence || [@company.city, @company.country].compact_blank.join(", ").presence

    def footer
      count = open_roles
      count.zero? ? "On DevCongress Connect" : "#{count} open #{"role".pluralize(count)}"
    end

    def avatar = avatar_for(@company.display_name, seed: @company.slug, shape: :square)

    def route = [:og_company_image, {slug: @company.slug}]

    def cache_key = ["company", @company.cache_key_with_version, open_roles]

    private

    def open_roles = @open_roles ||= Hiring::JobPost.visible_to(nil).where(company: @company).count
  end
end
