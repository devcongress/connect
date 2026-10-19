require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  test "renders the landing page" do
    get root_path
    assert_response :success
    assert_select "h1", /Africa.s builders/
  end

  test "builder sections share one public rotation without duplicates" do
    skill = Skill.create!(name: "Ruby")
    public_profiles = 6.times.map do |index|
      profile = create_profile!(name: "Public Builder #{index}", visibility: :everyone)
      profile.profile_skills.create!(skill:)
      profile
    end
    create_profile!(name: "Mo Members", handle: "momo", visibility: :members)
    create_profile!(name: "Hal Hidden", handle: "hal", visibility: :hidden)

    get root_path

    assert_response :success
    assert_includes response.body, "Meet some builders"
    assert_not_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"
    assert_not_includes response.body, "A new builder joined"
    public_profiles.each do |profile|
      assert_select "a[href=?]", developer_page_path(profile.handle), count: 1
    end
  end
end
