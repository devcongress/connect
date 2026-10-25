require "test_helper"

class Developers::DirectorySearchTest < ActiveSupport::TestCase
  include AccountsTestHelper

  test "filters by skill and optionally requires experience-backed evidence" do
    skill = Skill.create!(name: "Ruby")
    unbacked = create_profile!(handle: "unbacked")
    unbacked.profile_skills.create!(skill:)
    experienced = create_profile!(handle: "experienced")
    experienced_skill = experienced.profile_skills.create!(skill:)
    experience = experienced.experiences.create!(title: "Engineer", company_name: "Acme", started_on: Date.new(2020, 1, 1))
    experience.profile_skills << experienced_skill

    assert_equal [unbacked, experienced].sort_by(&:id), search(skill:).sort_by(&:id)
    assert_equal [experienced], search(skill:, has_experience: true).to_a
    assert_equal [experienced], search(has_experience: true).to_a
  end

  test "composes the directory filters into one relation" do
    matching = create_profile!(
      name: "Ruby Builder",
      country: "Ghana",
      availability: :looking,
      remote_ok: true
    )
    other = create_profile!(name: "Python Builder", country: "Kenya", availability: :open, remote_ok: false)

    result = search(query: "Ruby", country: "Ghana", availability: "looking", remote: true)

    assert_equal [matching], result.to_a
    assert_not_includes result, other
  end

  private

  def search(**filters)
    Developers::DirectorySearch.call(scope: Developers::Profile.all, **filters)
  end
end
