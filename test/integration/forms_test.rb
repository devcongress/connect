require "test_helper"

class FormsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @user = create_user!
    @company = create_company!(owner: @user, name: "Acme Labs")
    create_profile!(user: @user, name: "Ama Serwaa Mensah", handle: "ama")
  end

  test "profiles keep the full name in step with its parts" do
    profile = @user.developer_profile
    assert_equal ["Ama", "Serwaa Mensah", "Ama Serwaa Mensah"], [profile.first_name, profile.other_names, profile.name]

    profile.update!(other_names: "Boateng")
    assert_equal "Ama Boateng", profile.name
  end

  test "countries and currencies come from the pickers' lists" do
    profile = @user.developer_profile
    profile.country = "Gotham"
    assert_not profile.valid?
    assert profile.errors[:country].any?

    job = @company.job_posts.new(title: "Dev", description: "Code.", salary_currency: "UCC")
    assert_not job.valid?
    assert job.errors[:salary_currency].any?
  end

  test "the profile form asks for first and other names, with country before city" do
    login_user(@user)
    get "/developer/ama/developers_profile/edit"
    assert_response :success

    assert_select "input[name='developers_profile[first_name]']"
    assert_select "input[name='developers_profile[other_names]']"
    assert_select "select[name='developers_profile[country]'] option[value='Ghana']"
    assert_operator response.body.index("developers_profile[country]"), :<, response.body.index("developers_profile[city]")
  end

  test "owners can edit their company's details" do
    login_user(@user)
    get "/company/acme-labs/company/edit"
    assert_response :success
    %w[name website description country city].each do |attribute|
      assert_select "[name='company[#{attribute}]']"
    end

    patch "/company/acme-labs/company", params: {company: {website: "https://acme.example", country: "Kenya", city: "Nairobi"}}
    assert_equal ["https://acme.example", "Kenya", "Nairobi"], @company.reload.slice(:website, :country, :city).values
  end

  test "the job form picks the currency from a list and labels the pay range" do
    login_user(@user)
    get "/company/acme-labs/hiring/job_posts/new"
    assert_response :success

    assert_select "select[name='hiring_job_post[salary_currency]'] option[value='GHS']"
    assert_select "select[name='hiring_job_post[country]'] option[value='Ghana']"
    assert_includes response.body, "Pay from"
    assert_includes response.body, "Pay up to"
  end

  test "the job form shows frontend-only guidance for its description" do
    login_user(@user)

    get "/company/acme-labs/hiring/job_posts/new"
    assert_response :success
    assert_includes response.body, "Help people decide whether to apply. Cover the work, outcomes, requirements, team, and what success looks like."
    assert_job_description_checklist

    job = create_job!(company: @company)
    get "/company/acme-labs/hiring/job_posts/#{job.id}/edit"
    assert_response :success
    assert_job_description_checklist
  end

  test "onboarding takes the company's location" do
    other = create_user!
    login_user(other)

    post "/onboarding", params: {onboarding: {developer: "0", hiring: "1", company_name: "Kumasi Labs",
                                              company_country: "Ghana", company_city: "Kumasi"}}
    assert_equal ["Ghana", "Kumasi"], Company.find_by!(name: "Kumasi Labs").slice(:country, :city).values
  end

  private

  def assert_job_description_checklist
    assert_select ".job-description-checklist" do
      assert_select "legend", text: "Description checklist"
      assert_select "input[type=checkbox]:not([name])", count: 5
      assert_select "p", text: /not saved/
    end
  end
end
