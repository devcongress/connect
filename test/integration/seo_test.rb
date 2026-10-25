require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @public = create_profile!(name: "Pat Public", handle: "pat", visibility: :everyone, city: "Accra", country: "Ghana",
      headline: "Rails </script><b>dev</b>", github_url: "https://github.com/pat")
    @public.profile_skills.create!(skill: Skill.create!(name: "Elixir"))
    @members = create_profile!(name: "Mo Members", handle: "momo", visibility: :members)

    @company = create_company!(name: "Acme Labs")
    @job = create_job!(company: @company, title: "Backend Engineer", city: "Accra", country: "Ghana",
      salary_min: 50_000, salary_max: 80_000, salary_currency: "USD")
    @members_job = create_job!(company: @company, title: "Members Role", visibility: :members)
    @project = Showcase::Project.create!(owner: @public, title: "Kente", summary: "A weaving app", visibility: :everyone)
  end

  test "every public page has canonical, Open Graph and Twitter tags" do
    get "/devs", params: {q: "rails", page: 2}

    assert_select "link[rel=canonical][href='http://www.example.com/devs?page=2']"
    assert_select "meta[property='og:site_name'][content='DevCongress Connect']"
    assert_select "meta[property='og:title'][content='Developers']"
    assert_select "meta[property='og:url'][content='http://www.example.com/devs?page=2']"
    assert_select "meta[property='og:image'][content^='http://www.example.com/og/site.png?v=']"
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
    assert_select "meta[name='twitter:site'][content='@devcongress']"
  end

  test "the home page describes the site and DevCongress" do
    get "/"

    assert_select "meta[name=description]"
    website, organization = json_ld
    assert_equal "WebSite", website["@type"]
    assert_equal "Organization", organization["@type"]
    assert_equal ["https://x.com/devcongress"], organization["sameAs"]
  end

  test "public developer profiles get a profile card and a ProfilePage" do
    get "/@pat"

    assert_select "meta[property='og:type'][content='profile']"
    assert_select "meta[property='og:image'][content^='http://www.example.com/og/devs/pat.png?v=']"
    data = json_ld
    assert_equal "ProfilePage", data["@type"]
    person = data["mainEntity"]
    assert_equal ["Pat Public", "@pat", "Rails </script><b>dev</b>"], person.values_at("name", "alternateName", "description")
    assert_equal({"@type" => "PostalAddress", "addressLocality" => "Accra", "addressCountry" => "GH"}, person["address"])
    assert_equal ["https://github.com/pat"], person["sameAs"]
    assert_equal ["Elixir"], person["knowsAbout"]
    assert_not_includes response.body, "Rails </script>", "user text must not close the JSON-LD script tag"
  end

  test "members-only pages get no structured data and the site card" do
    login_user(create_user!)

    get "/@momo"
    assert_select "script[type='application/ld+json']", count: 0
    assert_select "meta[property='og:image'][content^='http://www.example.com/og/site.png']"

    get "/jobs/#{@members_job.to_param}"
    assert_select "script[type='application/ld+json']", count: 0
    assert_select "meta[property='og:image'][content^='http://www.example.com/og/site.png']"
  end

  test "public jobs get a JobPosting" do
    get "/jobs/#{@job.to_param}"

    assert_select "meta[property='og:image'][content^='http://www.example.com/og/jobs/#{@job.id}.png?v=']"
    data = json_ld
    assert_equal "JobPosting", data["@type"]
    assert_equal "Backend Engineer", data["title"]
    assert_equal "FULL_TIME", data["employmentType"]
    assert_equal({"@type" => "Organization", "name" => "Acme Labs", "sameAs" => "http://www.example.com/companies/#{@company.slug}"}, data["hiringOrganization"])
    assert_equal "GH", data.dig("jobLocation", "address", "addressCountry")
    assert_equal({"@type" => "QuantitativeValue", "unitText" => "YEAR", "minValue" => 50_000, "maxValue" => 80_000}, data.dig("baseSalary", "value"))
    assert data["directApply"]
  end

  test "company pages get an Organization" do
    @company.update!(
      tagline: "Infrastructure for growing teams",
      industry: "Developer tools",
      founded_year: 2018,
      github_url: "https://github.com/acme",
      x_url: "https://x.com/acme"
    )
    get "/companies/#{@company.slug}"

    assert_select "meta[property='og:image'][content^='http://www.example.com/og/companies/#{@company.slug}.png?v=']"
    data = json_ld
    assert_equal ["Organization", "Acme Labs", "Infrastructure for growing teams", "Developer tools", "2018"],
      data.values_at("@type", "name", "slogan", "industry", "foundingDate")
    assert_equal ["https://github.com/acme", "https://x.com/acme"], data["sameAs"]
  end

  test "public projects get a CreativeWork crediting the owner" do
    get "/projects/#{@project.slug}"

    assert_select "meta[property='og:image'][content^='http://www.example.com/og/projects/#{@project.slug}.png?v=']"
    data = json_ld
    assert_equal ["CreativeWork", "Kente", "A weaving app"], data.values_at("@type", "name", "description")
    assert_equal({"@type" => "Person", "name" => "Pat Public", "url" => "http://www.example.com/@pat"}, data["author"])
  end

  private

  def json_ld
    JSON.parse(css_select("script[type='application/ld+json']").sole.text)
  end
end
