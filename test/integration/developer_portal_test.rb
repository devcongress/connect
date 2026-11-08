require "test_helper"

class DeveloperPortalTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @profile = create_profile!(handle: "ada")
    @other = create_profile!(handle: "grace")
    @other.experiences.create!(title: "Admiral", company_name: "US Navy", started_on: Date.new(1943, 1, 1))
    login_user(@profile.user)
  end

  test "shows the owner's own portal" do
    get "/developer/ada"
    assert_response :success
    assert_select "h1", /#{@profile.name}/

    get "/developer/ada/developers_profile"
    assert_response :success
    assert_select ".developer-profile-display" do
      assert_select "h3", text: "About"
      assert_select "#developers_profile_#{@profile.id}_name_label", text: "Name"
    end

    get "/developer/ada/developers_profile/edit"
    assert_response :success
  end

  test "the dashboard shows who can see the profile" do
    get "/developer/ada"
    assert_select "[data-visibility-banner=members]", /signed-in members only/
    assert_select "[data-visibility-banner] a[href=?]", "/developer/ada/developers_profile/edit#developers_profile_#{@profile.id}_visibility"

    @profile.update!(visibility: :hidden)
    get "/developer/ada"
    assert_select "[data-visibility-banner=hidden]", /Only you can see it/

    @profile.update!(visibility: :everyone)
    get "/developer/ada"
    assert_select "[data-visibility-banner=everyone]", /public/
  end

  test "cannot open someone else's profile portal" do
    get "/developer/grace"
    assert_includes [403, 404], response.status
  end

  test "manages experience within the profile only" do
    post "/developer/ada/developers/experiences", params: {developers_experience: {
      title: "Analyst", company_name: "Analytical Engines", started_on: "1842-01-01"
    }}
    assert_response :redirect

    experience = @profile.experiences.sole
    assert_equal "Analyst", experience.title

    get "/developer/ada/developers/experiences"
    assert_response :success
    assert_includes response.body, "Analytical Engines"
    assert_not_includes response.body, "US Navy"
  end

  test "links experience to skills from the owner's profile only" do
    ruby = @profile.profile_skills.create!(skill: Skill.create!(name: "Ruby"))
    elixir = @profile.profile_skills.create!(skill: Skill.create!(name: "Elixir"))
    other_skill = @other.profile_skills.create!(skill: Skill.create!(name: "COBOL"))

    get "/developer/ada/developers/experiences/new"
    assert_response :success
    assert_includes response.body, "Ruby"
    assert_includes response.body, "Elixir"
    assert_not_includes response.body, "COBOL"

    post "/developer/ada/developers/experiences", params: {developers_experience: {
      title: "Analyst", company_name: "Analytical Engines", started_on: "1842-01-01",
      profile_skills: [ruby.to_signed_global_id.to_s, other_skill.to_signed_global_id.to_s]
    }}
    experience = @profile.experiences.find_by!(title: "Analyst")
    assert_equal [ruby], experience.profile_skills.to_a

    patch "/developer/ada/developers/experiences/#{experience.id}", params: {developers_experience: {
      profile_skills: [elixir.to_signed_global_id.to_s]
    }}
    assert_response :redirect
    assert_equal [elixir], experience.profile_skills.reload
  end

  test "shows frontend-only guidance for an experience description" do
    get "/developer/ada/developers/experiences/new"
    assert_response :success
    assert_includes response.body, "Describe your contribution, not just the role. Use 2–4 short bullets."
    assert_description_checklist

    experience = @profile.experiences.create!(
      title: "Analyst",
      company_name: "Analytical Engines",
      started_on: Date.new(1842, 1, 1)
    )
    get "/developer/ada/developers/experiences/#{experience.id}/edit"
    assert_response :success
    assert_description_checklist
  end

  test "adds skills from the shared taxonomy" do
    skill = Skill.create!(name: "Ruby")

    post "/developer/ada/developers/profile_skills", params: {developers_profile_skill: {skill: skill.to_signed_global_id.to_s, level: "expert", years: 5}}
    assert_response :redirect

    assert_equal [skill], @profile.skills.to_a
  end

  private

  def assert_description_checklist
    assert_select ".experience-description-checklist" do
      assert_select "legend", text: "Description checklist"
      assert_select "input[type=checkbox]:not([name])", count: 4
      assert_select "details", count: 0
      assert_select "p", text: /not saved/
    end
  end
end
