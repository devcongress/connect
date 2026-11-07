require "test_helper"

class NotificationDmsTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  setup do
    @ama = create_profile!(name: "Ama Owusu")
    @kofi = create_profile!(name: "Kofi Boateng")
  end

  def button_url(dm) = dm.blocks.last[:elements].sole[:url]

  test "followed" do
    follow = Network::Follow.create!(follower: @ama, followee: @kofi)
    dm = Network::FollowedDm.new(follow:)

    assert_equal @kofi.user, dm.recipient
    assert_equal "Ama Owusu followed you on DevCongress Connect", dm.text
    assert_equal Slack.url("/@#{@ama.handle}"), button_url(dm)

    Network::Follow.create!(follower: @kofi, followee: @ama)
    assert_equal "You're now connected with Ama Owusu", dm.text
  end

  test "application received and status changed" do
    owner = create_user!
    company = create_company!(owner:, name: "Acme")
    job = create_job!(company:, title: "Rails Engineer")
    application = job.job_applications.create!(profile: @kofi)

    received = Hiring::ApplicationReceivedDm.new(job_application: application, recipient: owner)
    assert_equal owner, received.recipient
    assert_equal "New applicant for Rails Engineer: Kofi Boateng", received.text
    assert_equal Slack.url(received.company_portal_application_path(company, application)), button_url(received)

    application.update!(status: :shortlisted)
    changed = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: "Free Tuesday?")
    assert_equal @kofi.user, changed.recipient
    assert_equal "You're on the shortlist for Rails Engineer", changed.text
    assert(changed.blocks.any? { it.dig(:text, :text)&.include?("> Free Tuesday?") })

    multi = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: "Line one\nLine two")
    assert(multi.blocks.any? { it.dig(:text, :text)&.include?("> Line one\n> Line two") })

    application.update!(status: :rejected)
    rejected = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: nil)
    assert_equal Slack.url("/jobs"), button_url(rejected)
  end

  test "project credits" do
    project = Showcase::Project.create!(owner: @ama, title: "Trotro Times")
    credit = project.contributors.create!(profile: @kofi)

    invited = Showcase::CreditInvitedDm.new(contributor: credit)
    assert_equal @kofi.user, invited.recipient
    assert_equal "Ama Owusu credited you on Trotro Times", invited.text

    confirmed = Showcase::CreditConfirmedDm.new(contributor: credit)
    assert_equal @ama.user, confirmed.recipient
    assert_equal "Kofi Boateng confirmed they worked on Trotro Times", confirmed.text
  end

  test "user-controlled values are escaped in text and blocks" do
    project = Showcase::Project.create!(owner: @ama, title: "Q&A <b>Hub</b>")
    credit = project.contributors.create!(profile: @kofi)

    invited = Showcase::CreditInvitedDm.new(contributor: credit)
    assert_equal "Ama Owusu credited you on Q&amp;A &lt;b&gt;Hub&lt;/b&gt;", invited.text
    assert_includes invited.blocks.first.dig(:text, :text), "*Ama Owusu credited you on Q&amp;A &lt;b&gt;Hub&lt;/b&gt;*"

    owner = create_user!
    job = create_job!(company: create_company!(owner:, name: "A&B <Co>"), title: "Dev <script>")
    application = job.job_applications.create!(profile: @kofi)
    application.update!(status: :reviewing)
    changed = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: "a < b & c")
    assert_equal "An update on your application to A&amp;B &lt;Co&gt;", changed.text
    assert_includes changed.blocks.second.dig(:text, :text), "> a &lt; b &amp; c"
    refute_includes changed.blocks.first.dig(:text, :text), "&amp;amp;"

    received = Hiring::ApplicationReceivedDm.new(job_application: application, recipient: owner)
    assert_equal "New applicant for Dev &lt;script&gt;: Kofi Boateng", received.text
  end

  test "call sites enqueue DMs alongside emails" do
    Rails.cache.clear
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Network::FollowedDm" }) do
      Network::Follow.create!(follower: @ama, followee: @kofi)
    end

    owner = create_user!
    job = create_job!(company: create_company!(owner:))
    application = nil
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Hiring::ApplicationReceivedDm" && args.last[:recipient] == owner }) do
      application = job.job_applications.create!(profile: @kofi)
    end
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Hiring::ApplicationStatusChangedDm" }) do
      application.move_to!(:shortlisted, message: "Hi")
    end

    project = Showcase::Project.create!(owner: @ama, title: "Trotro Times")
    credit = nil
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Showcase::CreditInvitedDm" }) do
      credit = project.contributors.create!(profile: @kofi)
    end
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Showcase::CreditConfirmedDm" }) do
      credit.confirm!
    end
  end
end
