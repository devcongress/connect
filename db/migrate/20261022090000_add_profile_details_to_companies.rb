class AddProfileDetailsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :tagline, :string
    add_column :companies, :organization_type, :string
    add_column :companies, :industry, :string
    add_column :companies, :founded_year, :integer
    add_column :companies, :github_url, :string
    add_column :companies, :linkedin_url, :string
    add_column :companies, :x_url, :string
  end
end
