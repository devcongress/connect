class CompanyPolicy < ::ResourcePolicy
  # Core actions

  # def create?
  #   true
  # end

  # def read?
  #   true
  # end

  # Personal posting spaces belong to one person, so they have no team.
  def invite_user?
    current_membership&.owner? && !record.personal?
  end

  # Core attributes

  def permitted_attributes_for_create
    [:name, :slug, :logo, :tagline, :organization_type, :industry, :founded_year,
      :website, :github_url, :linkedin_url, :x_url, :description, :city, :country]
  end

  def permitted_attributes_for_read
    [:name, :slug, :logo, :tagline, :organization_type, :industry, :founded_year,
      :website, :github_url, :linkedin_url, :x_url, :description, :city, :country]
  end

  # Associations

  def permitted_associations
    %i[]
  end
end
