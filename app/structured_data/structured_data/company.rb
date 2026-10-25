module StructuredData
  class Company < Base
    def to_h
      company = @record
      links = [company.website, company.github_url, company.linkedin_url, company.x_url].compact_blank
      {
        "@context" => CONTEXT,
        "@type" => "Organization",
        "name" => company.name,
        "url" => view.public_company_url(company.slug),
        "description" => company.description,
        "slogan" => company.tagline,
        "industry" => company.industry,
        "foundingDate" => company.founded_year&.to_s,
        "address" => address(city: company.city, country: company.country),
        "logo" => logo_url(company),
        "sameAs" => links.presence
      }.compact_blank
    end

    private

    def logo_url(company)
      return unless company.logo.attached?

      view.public_company_logo_url(slug: company.slug, v: company.logo_attachment.updated_at.to_i)
    end
  end
end
