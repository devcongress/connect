require "test_helper"

class Developers::ProfileTest < ActiveSupport::TestCase
  include AccountsTestHelper

  test "normalizes the handle and uses it in URLs" do
    profile = create_profile!(handle: " @Ada ")
    assert_equal "ada", profile.handle
    assert_equal "ada", profile.to_param
  end

  test "rejects badly formed and reserved handles" do
    profile = Developers::Profile.new(first_name: "Ada", user: create_user!)

    ["a", "has space", "-leading", "admin", "developer"].each do |handle|
      profile.handle = handle
      assert_not profile.valid?, "expected #{handle.inspect} to be invalid"
      assert profile.errors[:handle].any?
    end
  end

  test "allows one profile per user" do
    profile = create_profile!
    duplicate = Developers::Profile.new(user: profile.user, first_name: "Again", handle: "again")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user], "already has a developer profile"
  end

  test "tracks profile completeness" do
    profile = create_profile!
    assert_equal 0, profile.completeness_percent

    profile.update!(headline: "Engineer", bio: "Hi", country: "Ghana", github_url: "https://github.com/ada")
    %w[Ruby Rails SQLite].each { |name| profile.profile_skills.create!(skill: Skill.create!(name:)) }
    profile.experiences.create!(title: "Dev", company_name: "Acme", started_on: Date.new(2020, 1, 1))

    assert_equal 100, profile.reload.completeness_percent
  end

  test "finds profiles by skill and optionally requires experience" do
    skill = Skill.create!(name: "Ruby")
    unbacked = create_profile!(handle: "unbacked")
    unbacked.profile_skills.create!(skill:)
    experienced = create_profile!(handle: "experienced")
    experienced_skill = experienced.profile_skills.create!(skill:)
    experience = experienced.experiences.create!(title: "Engineer", company_name: "Acme", started_on: Date.new(2020, 1, 1))
    experience.profile_skills << experienced_skill

    assert_equal [unbacked, experienced].sort_by(&:id), Developers::Profile.with_skill(skill).sort_by(&:id)
    assert_equal [experienced], Developers::Profile.with_skill(skill, has_experience: true).to_a
    assert_equal [experienced], Developers::Profile.with_skill(nil, has_experience: true).to_a
  end

  test "only accepts http(s) links" do
    profile = create_profile!
    profile.github_url = "javascript:alert(1)"
    assert_not profile.valid?

    profile.github_url = "https://github.com/ada"
    assert profile.valid?
  end
end
