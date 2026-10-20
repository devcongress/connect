require "test_helper"

class HomepageProjectSelectorTest < ActiveSupport::TestCase
  include AccountsTestHelper

  TEST_SECRET = "homepage-project-selector-test-secret"
  PERIOD = Date.new(2026, 10, 19)

  test "selects only public projects owned by public profiles" do
    public_owner = create_profile!(visibility: :everyone)
    hidden_owner = create_profile!(visibility: :hidden)
    public_project = create_project!(owner: public_owner, title: "Public project")
    create_project!(owner: public_owner, title: "Members project", visibility: :members)
    create_project!(owner: hidden_owner, title: "Hidden owner project")

    selected = select_projects

    assert_equal [public_project.id], selected.map(&:id)
  end

  test "returns three unique projects when enough public projects exist" do
    owner = create_profile!(visibility: :everyone)
    5.times { |index| create_project!(owner:, title: "Project #{index}") }

    selected = select_projects

    assert_equal 3, selected.size
    assert_equal 3, selected.map(&:id).uniq.size
  end

  test "is stable within a period and rotates for a later period" do
    owner = create_profile!(visibility: :everyone)
    8.times { |index| create_project!(owner:, title: "Project #{index}") }

    first = select_projects(period: PERIOD).map(&:id)
    repeated = select_projects(period: PERIOD).map(&:id)
    next_period = select_projects(period: PERIOD + 1).map(&:id)
    repeated_next_period = select_projects(period: PERIOD + 1).map(&:id)

    assert_equal first, repeated
    assert_equal next_period, repeated_next_period
    refute_equal first, next_period
  end

  private

  def select_projects(period: PERIOD)
    HomepageProjectSelector.call(period:, secret: TEST_SECRET)
  end

  def create_project!(owner:, title:, visibility: :everyone)
    Showcase::Project.create!(owner:, title:, visibility:)
  end
end
