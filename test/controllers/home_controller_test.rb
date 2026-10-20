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

  test "projects use a public rotation instead of recency" do
    public_owner = create_profile!(visibility: :everyone)
    members_owner = create_profile!(visibility: :members)
    public_projects = 3.times.map do |index|
      Showcase::Project.create!(owner: public_owner, title: "Public Project #{index}")
    end
    Showcase::Project.create!(owner: public_owner, title: "Members Project", visibility: :members)
    Showcase::Project.create!(owner: members_owner, title: "Members Owner Project")

    get root_path

    assert_response :success
    assert_includes response.body, "Explore projects"
    assert_not_includes response.body, "Members Project"
    assert_not_includes response.body, "Members Owner Project"
    public_projects.each do |project|
      assert_select "a[href=?]", public_project_path(project.slug), count: 1
    end
  end
end
