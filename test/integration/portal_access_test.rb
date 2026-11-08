require "test_helper"

class PortalAccessTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @profile = create_profile!
    @user = @profile.user
    @company = create_company!(owner: @user, name: "Acme Labs")
    @other_company = create_company!(name: "Other Co")
  end

  test "guests are sent to the user login" do
    ["/dashboard", "/company/#{@company.to_param}", "/developer/#{@profile.to_param}"].each do |path|
      get path
      assert_redirected_to "/users/login"
    end
  end

  test "users land on the dashboard after logging in" do
    login_user(@user)

    assert_equal "/dashboard", path.chomp("/")
    assert_response :success
    assert_select "h1", "Welcome back, Ada"
    assert_select "a[href='/developer/#{@profile.handle}']"
    assert_select "a[href='/company/acme-labs']"
  end

  test "portal page titles use the product name" do
    login_user(@user)

    ["/dashboard", "/developer/#{@profile.to_param}", "/company/#{@company.to_param}"].each do |path|
      get path
      assert_select "title", /DevCongress Connect\z/
    end
  end

  test "the context switcher lists the user's profile and companies only" do
    login_user(@user)
    get "/developer/#{@profile.to_param}"

    assert_select "details summary[aria-label='Switch context']"
    assert_select "details a[href='/dashboard/']", text: /Dashboard/
    assert_select "details a[href='/developer/#{@profile.handle}']"
    assert_select "details a[href='/company/acme-labs']"
    assert_select "details a[href='/company/#{@other_company.to_param}']", count: 0
  end

  test "portal navigation distinguishes the public site from the dashboard" do
    login_user(@user)

    ["/dashboard", "/developer/#{@profile.to_param}", "/company/#{@company.to_param}"].each do |path|
      get path

      assert_select "aside#sidebar-navigation a[aria-label='DevCongress Connect home'][href='/']"
      assert_select "nav.pu-topbar a[aria-label='DevCongress Connect home'][href='/']"
      assert_select "a[href='/dashboard/']", text: /Dashboard/
    end
  end

  test "users can open companies they belong to, and no others" do
    login_user(@user)

    get "/company/#{@company.to_param}"
    assert_response :success

    get "/company/#{@other_company.to_param}"
    assert_includes [403, 404], response.status
  end

  test "users cannot reach the admin portal" do
    login_user(@user)

    get "/admin"
    assert_redirected_to "/admins/login"
  end
end
