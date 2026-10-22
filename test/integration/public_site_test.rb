require "test_helper"

class PublicSiteTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @public = create_profile!(name: "Pat Public", handle: "pat", visibility: :everyone, contact_email: "pat@example.com",
      contact_visibility: :members, availability: :looking, remote_ok: true, country: "Ghana")
    @members = create_profile!(name: "Mo Members", handle: "momo", visibility: :members, contact_email: "mo@example.com",
      contact_visibility: :everyone, country: "Nigeria")
    @hidden = create_profile!(name: "Hal Hidden", handle: "hal", visibility: :hidden)
    @elixir = Skill.create!(name: "Elixir", category: "Languages", description: "Elixir is a functional language for reliable, concurrent systems.")
    @public.profile_skills.create!(skill: @elixir)

    @company = create_company!(name: "Acme Labs")
    @public_job = create_job!(company: @company, title: "Public Role", apply_url: "https://acme.test/apply")
    @members_job = create_job!(company: @company, title: "Members Role", visibility: :members)
    create_job!(company: @company, title: "Draft Role", published: false)
    create_job!(company: @company, title: "Filled Role").mark_filled!
  end

  test "guests see only public profiles" do
    get "/devs"
    assert_response :success
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"

    get "/@pat"
    assert_response :success
    get "/@momo"
    assert_response :not_found
    get "/@hal"
    assert_response :not_found
  end

  test "members also see members-only profiles, never hidden ones" do
    login_user(create_user!)

    get "/devs"
    assert_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"

    get "/@momo"
    assert_response :success
    get "/@hal"
    assert_response :not_found
  end

  test "owners can always see their own profile" do
    login_user(@hidden.user)

    get "/@hal"
    assert_response :success
    assert_includes response.body, "only you can see it"
  end

  test "contact details follow the contact visibility setting" do
    get "/@pat"
    assert_not_includes response.body, "pat@example.com"
    assert_includes response.body, "to see contact details"

    login_user(create_user!)
    get "/@pat"
    assert_includes response.body, "pat@example.com"
    get "/@momo"
    assert_includes response.body, "mo@example.com"
  end

  test "directory search and filters" do
    get "/devs", params: {q: "elixir"}
    assert_includes response.body, "Pat Public"

    login_user(create_user!)
    get "/devs", params: {country: "Nigeria"}
    assert_includes response.body, "Mo Members"
    assert_not_includes response.body, "Pat Public"

    get "/devs", params: {availability: "looking", remote: "1"}
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"

    get "/devs", params: {skill: "elixir"}
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
  end

  test "skill pages explain the skill and remain visible with no matches" do
    get "/devs", params: {skill: "elixir"}

    assert_response :success
    assert_select "h1", "Elixir developers"
    assert_includes response.body, @elixir.description
    assert_select "title", "Elixir developers · DevCongress Connect"
    assert_select "meta[name=description][content=?]", @elixir.description
    assert_select "link[rel=canonical][href='http://www.example.com/technical-skills/elixir']"
    assert_select "meta[name=robots][content=noindex]"

    get "/technical-skills/elixir", params: {country: "Nowhere"}

    assert_response :success
    assert_select "h1", "Elixir developers"
    assert_includes response.body, @elixir.description
    assert_includes response.body, "No one matches that yet."
  end

  test "unknown skills have an intentional not-found state" do
    get "/technical-skills/not-a-real-skill"
    assert_response :not_found

    get "/devs", params: {skill: "not-a-real-skill"}
    assert_response :not_found
  end

  test "curated skill pages link to resources and reference companies using the skill" do
    react = Skill.create!(
      name: "React",
      category: "Frontend",
      description: "React builds component-based interfaces.",
      website_url: "https://react.dev/",
      source_url: "https://github.com/react/react",
      why_description: "React's component model helps teams build complex interfaces.",
      company_examples: [{"name" => "Shopify", "url" => "https://shopify.dev/docs/api/hydrogen-react/latest"}],
      content_curated: true
    )

    get "/technical-skills/#{react.slug}"

    assert_response :success
    assert_select "a[href='https://react.dev/']", "Official website ↗"
    assert_select "a[href='https://github.com/react/react']", "GitHub ↗"
    assert_select "h1 + p + p", text: /#{Regexp.escape(react.why_description)}.*Companies using React include/m do
      assert_select "a[href='https://shopify.dev/docs/api/hydrogen-react/latest']", "Shopify ↗"
    end
    assert_select "h2", count: 0
    assert_select "meta[name=robots]", count: 0
  end

  test "user-written markdown can't inject markup" do
    @public.update!(bio: "Hello <script>alert(1)</script> **world**")
    get "/@pat"
    assert_includes response.body, "<strong>world</strong>"
    assert_not_includes response.body, "<script>alert(1)</script>"
  end

  test "experience entries show the profile skills used there" do
    experience = @public.experiences.create!(title: "Engineer", company_name: "Acme", started_on: Date.new(2020, 1, 1))
    experience.profile_skills << @public.profile_skills.sole

    get "/@pat"

    assert_select ".experience-skills[aria-label=?]", "Skills used in Engineer at Acme" do
      assert_select "a[href=?]", "/technical-skills/elixir", text: "Elixir"
    end
  end

  test "guests see only public, active jobs" do
    get "/jobs"
    assert_response :success
    assert_includes response.body, "Public Role"
    %w[Members\ Role Draft\ Role Filled\ Role].each { |title| assert_not_includes response.body, title }

    get "/jobs/#{@public_job.to_param}"
    assert_response :success
    assert_includes response.body, "Log in to apply"
    assert_includes response.body, "https://acme.test/apply"

    get "/jobs/#{@members_job.to_param}"
    assert_response :not_found
  end

  test "members see members-only jobs and the right way to apply" do
    user = create_user!
    login_user(user)

    get "/jobs"
    assert_includes response.body, "Members Role"

    get "/jobs/#{@members_job.to_param}"
    assert_response :success
    assert_includes response.body, "Create a developer profile to apply"

    profile = create_profile!(user:, handle: "applicant")
    get "/jobs/#{@public_job.to_param}"
    assert_select "a[href='/developer/applicant/hiring/job_posts/#{@public_job.to_param}/record_actions/apply']", "Apply with your profile"

    @public_job.job_applications.create!(profile:)
    get "/jobs/#{@public_job.to_param}"
    assert_includes response.body, "View your application"
  end

  test "company pages list only the jobs the viewer can see" do
    get "/companies/acme-labs"
    assert_response :success
    assert_includes response.body, "Public Role"
    assert_not_includes response.body, "Members Role"

    get "/companies/nope"
    assert_response :not_found
  end

  test "company directory lists organizations and excludes personal posting spaces" do
    @company.update!(description: "Builds useful tools.", city: "Accra", country: "Ghana", website: "https://acme.test")
    quiet = create_company!(name: "Quiet Works")
    quiet.update!(description: "A distributed product studio.", city: "Lagos", country: "Nigeria")
    personal = Company.personal_for!(@public.user)

    get "/companies"

    assert_response :success
    assert_select "h1", "Companies"
    assert_select "a[href='/companies/#{@company.slug}']"
    assert_select "a[href='/companies/#{quiet.slug}']"
    assert_select "a[href='/companies/#{personal.slug}']", count: 0
    assert_select "p", text: "2 companies"
    assert_includes response.body, "1 open job"

    get "/companies", params: {q: "acme"}
    assert_includes response.body, "Acme Labs"
    assert_not_includes response.body, "Quiet Works"

    get "/companies", params: {country: "Nigeria"}
    assert_includes response.body, "Quiet Works"
    assert_not_includes response.body, "Acme Labs"

    login_user(create_user!)
    get "/companies", params: {q: "acme"}
    assert_includes response.body, "2 open jobs"
  end

  test "the landing page company count links to the same organizations as the directory" do
    Company.personal_for!(@public.user)

    get "/"

    assert_select "a.dc-box[href='/companies']" do
      assert_select "span", text: Company.organizations.count.to_s
      assert_select "span", text: "Companies"
    end
    assert_select "nav[aria-label='Primary'] a[href='/companies']", text: "Companies", minimum: 1
  end

  test "the landing page only shows what the viewer can see" do
    get "/"
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
    assert_includes response.body, "Public Role"
    assert_not_includes response.body, "Members Role"
    assert_select "a[href='/@pat']"
  end

  test "support links use the stable DevCongress donation path" do
    get "/"

    assert_response :success
    assert_select "a[href='https://devcongress.org/donate']", text: "Support us", count: 3
    assert_not_includes response.body, "paystack.shop/pay/devcongress-meetup"
  end
end
