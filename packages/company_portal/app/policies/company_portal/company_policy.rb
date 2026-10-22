class CompanyPortal::CompanyPolicy < ::CompanyPolicy
  include CompanyPortal::ResourcePolicy

  def update?
    current_membership&.owner?
  end

  def destroy?
    false
  end

  # The slug stays fixed so existing company URLs keep working.
  def permitted_attributes_for_read
    attributes = [:name, :website, :description, :country, :city]
    return attributes if record.personal?

    attributes + [:logo, :tagline, :organization_type, :industry, :founded_year, :github_url, :linkedin_url, :x_url]
  end

  def permitted_attributes_for_update
    permitted_attributes_for_read
  end

  def permitted_associations
    []
  end
end
