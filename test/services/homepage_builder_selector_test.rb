require "test_helper"

class HomepageBuilderSelectorTest < ActiveSupport::TestCase
  include AccountsTestHelper

  TEST_SECRET = "homepage-builder-selector-test-secret"
  PERIOD = Date.new(2026, 10, 19)

  test "selects only profiles visible to everyone" do
    public_profile = create_profile!(visibility: :everyone)
    public_profile.profile_skills.create!(skill: create_skill!)
    members_profile = create_profile!(visibility: :members)
    members_profile.profile_skills.create!(skill: create_skill!)
    hidden_profile = create_profile!(visibility: :hidden)
    hidden_profile.experiences.create!(experience_attributes)

    selected = select_builders

    assert_equal [public_profile.id], selected.map(&:id)
  end

  test "prefers profiles with a skill or experience and uses empty profiles as fallback" do
    skill = create_skill!
    skill_only = create_profile!(visibility: :everyone)
    skill_only.profile_skills.create!(skill:)
    experience_only = create_profile!(visibility: :everyone)
    experience_only.experiences.create!(experience_attributes)
    both = create_profile!(visibility: :everyone)
    both.profile_skills.create!(skill:)
    both.experiences.create!(experience_attributes)
    empty_profiles = 2.times.map { create_profile!(visibility: :everyone) }

    selected = select_builders(limit: 4)

    assert_equal [skill_only.id, experience_only.id, both.id].sort, selected.first(3).map(&:id).sort
    assert_includes empty_profiles.map(&:id), selected.last.id
  end

  test "returns six unique profiles when enough public profiles exist" do
    8.times { create_profile!(visibility: :everyone) }

    selected = select_builders

    assert_equal 6, selected.size
    assert_equal 6, selected.map(&:id).uniq.size
  end

  test "is stable within a period and rotates for a later period" do
    skill = create_skill!
    10.times do
      profile = create_profile!(visibility: :everyone)
      profile.profile_skills.create!(skill:)
    end

    first = select_builders(period: PERIOD).map(&:id)
    repeated = select_builders(period: PERIOD).map(&:id)
    next_period = select_builders(period: PERIOD + 1).map(&:id)
    repeated_next_period = select_builders(period: PERIOD + 1).map(&:id)

    assert_equal first, repeated
    assert_equal next_period, repeated_next_period
    refute_equal first, next_period
  end

  test "does not ask the database for random ordering" do
    8.times { create_profile!(visibility: :everyone) }
    queries = []
    subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
      queries << payload[:sql]
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      select_builders
    end

    assert queries.any?
    assert queries.none? { |sql| sql.match?(/ORDER BY (?:RANDOM|RAND)\s*\(/i) }
  end

  private

  def select_builders(period: PERIOD, limit: HomepageBuilderSelector::LIMIT)
    HomepageBuilderSelector.call(period:, limit:, secret: TEST_SECRET)
  end

  def create_skill!
    Skill.create!(name: "Skill #{SecureRandom.hex(4)}")
  end

  def experience_attributes
    {title: "Developer", company_name: "Acme", started_on: Date.new(2020, 1, 1)}
  end
end
