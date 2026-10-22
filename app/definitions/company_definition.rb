class CompanyDefinition < ::ResourceDefinition
  action :invite_user, interaction: Company::InviteUserInteraction, category: :secondary

  modal false
  submit_and_continue false

  field :description, as: :markdown
  field :website, as: :url
  field :logo, condition: -> { !object.personal? }
  field :tagline, condition: -> { !object.personal? }
  field :organization_type, condition: -> { !object.personal? }
  field :industry, condition: -> { !object.personal? }
  field :founded_year, label: "Year of establishment", condition: -> { !object.personal? }
  field :github_url, as: :url, label: "GitHub", condition: -> { !object.personal? }
  field :linkedin_url, as: :url, label: "LinkedIn", condition: -> { !object.personal? }
  field :x_url, as: :url, label: "X (formerly Twitter)", condition: -> { !object.personal? }

  input :slug, hint: "Used in your company's URLs"
  input :logo, as: :file, allowed_file_types: CompanyLogoUploader::TYPES.values,
    max_file_size: CompanyLogoUploader::MAX_SIZE,
    hint: "A square JPG, PNG or WebP works best. Maximum 5 MB."
  input :tagline, hint: "A clear, one-line summary. Maximum 160 characters.", wrapper: {class: "col-span-full"}
  input :organization_type, as: :select, choices: Company::ORGANIZATION_TYPES.to_a, placeholder: "Choose a type"
  input :industry, placeholder: "e.g. Financial services"
  input :founded_year, placeholder: "e.g. 2018"
  input :website, placeholder: "https://"
  input :github_url, placeholder: "https://github.com/your-company"
  input :linkedin_url, placeholder: "https://linkedin.com/company/your-company"
  input :x_url, placeholder: "https://x.com/your-company"
  input :description, hint: "What the company does and what it's like to work there. Markdown supported.",
    wrapper: {class: "col-span-full"}
  input :country, as: :slim_select, choices: -> { World.country_names }, placeholder: "Choose a country"
  %i[
    name tagline logo slug
    country city
    organization_type industry description
    website github_url linkedin_url x_url
  ].each do |attribute|
    display attribute, wrapper: {class: "col-span-full"}
  end
  display :founded_year, formatter: ->(year) { year&.to_s }, wrapper: {class: "col-span-full"}

  form_layout do
    section :company, :name, :tagline, :logo, :slug, label: "Company", columns: 1
    section :about, :organization_type, :industry, :founded_year, :description, label: "About", columns: 2
    section :location, :country, :city, label: "Location", columns: 2
    section :links, :website, :github_url, :linkedin_url, :x_url, label: "Links", columns: 1
    ungrouped label: "Other"
  end

  display_layout do
    section :company, :name, :tagline, :logo, :slug, label: "Company"
    section :location, :country, :city, label: "Location"
    section :about, :organization_type, :industry, :founded_year, :description, label: "About"
    section :links, :website, :github_url, :linkedin_url, :x_url, label: "Links"
    ungrouped label: "Other"
  end
end
