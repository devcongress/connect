require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "derives a slug from the name" do
    assert_equal "acme-labs", Company.create!(name: "Acme Labs").slug
  end

  test "uses the slug in URLs" do
    company = Company.create!(name: "Acme Labs")
    assert_equal "acme-labs", company.to_param
  end

  test "accepts optional organization profile details" do
    company = Company.new(
      name: "Acme Labs",
      tagline: "Infrastructure for growing teams",
      organization_type: "business",
      industry: "Developer tools",
      founded_year: 2018,
      github_url: "https://github.com/acme",
      linkedin_url: "https://www.linkedin.com/company/acme",
      x_url: "https://x.com/acme"
    )

    assert company.valid?
    assert_equal "Business", company.organization_type_label
  end

  test "rejects unknown organization types and impossible founding years" do
    company = Company.new(name: "Acme Labs", organization_type: "startup", founded_year: Date.current.year + 1)

    assert_not company.valid?
    assert_includes company.errors[:organization_type], "is not included in the list"
    assert_includes company.errors[:founded_year], "must be between 1000 and #{Date.current.year}"
  end

  test "validates company profile links" do
    company = Company.new(name: "Acme Labs", github_url: "github", linkedin_url: "linkedin", x_url: "x")

    assert_not company.valid?
    assert company.errors[:github_url].any?
    assert company.errors[:linkedin_url].any?
    assert company.errors[:x_url].any?
  end
end
