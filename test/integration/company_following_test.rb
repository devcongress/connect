require "test_helper"

class CompanyFollowingTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @profile = create_profile!(name: "Ada Lovelace", handle: "ada", visibility: :everyone)
    @company = create_company!(name: "Acme Labs").tap do |company|
      company.update!(tagline: "Infrastructure for growing teams", city: "Accra", country: "Ghana")
    end
  end

  test "a developer follows and unfollows a company" do
    login_user(@profile.user)

    post "/companies/acme-labs/follow"

    assert_redirected_to "/companies/acme-labs"
    assert @profile.reload.following_company?(@company)
    assert_no_difference("Network::CompanyFollow.count") { post "/companies/acme-labs/follow" }
    follow_redirect!
    assert_includes response.body, "You&#39;re following Acme Labs."
    assert_select "form[action='/companies/acme-labs/follow'] button", text: /Following/
    assert_select "form[action='/companies/acme-labs/follow'] button span", text: "Unfollow"
    assert_select "span", text: /1 follower/

    delete "/companies/acme-labs/follow"

    assert_not @profile.reload.following_company?(@company)
  end

  test "following requires a developer profile" do
    post "/companies/acme-labs/follow"
    assert_redirected_to "/users/login"

    login_user(create_user!)
    post "/companies/acme-labs/follow"
    assert_redirected_to "/setup/developer/new"

    assert_equal 0, Network::CompanyFollow.count
  end

  test "personal posting spaces cannot be followed" do
    personal = Company.personal_for!(@profile.user)
    login_user(@profile.user)

    post "/companies/#{personal.slug}/follow"

    assert_response :not_found
    assert_equal 0, Network::CompanyFollow.count
  end

  test "followed companies appear in the developer network" do
    @profile.company_follows.create!(company: @company)
    login_user(@profile.user)

    get "/developer/ada/network", params: {tab: "companies"}

    assert_response :success
    assert_select "a[href='/companies/acme-labs']", "Acme Labs"
    assert_includes response.body, "Infrastructure for growing teams"
    assert_select "form[action='/companies/acme-labs/follow'] button", text: /Following/
  end
end
