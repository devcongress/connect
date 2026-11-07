require "test_helper"

class Hiring::PostTypesTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @company = create_company!(name: "Acme Labs") }

  def build_post(**attrs)
    @company.job_posts.new(title: "Thing", description: "Do it.", accepts_applications: true, **attrs)
  end

  test "pay reads naturally for every pay basis" do
    assert_equal "60,000 – 90,000 USD per year", build_post(salary_min: 60_000, salary_max: 90_000).pay
    assert_equal "40 USD per hour", build_post(employment_type: :contract, pay_period: :hour, salary_min: 40).pay
    assert_equal "500 GHS fixed budget", build_post(employment_type: :freelance, pay_period: :fixed, salary_min: 500, salary_currency: "GHS").pay
    assert_nil build_post.pay
  end

  test "only internships can be unpaid" do
    internship = build_post(employment_type: :internship, paid: false)
    internship.validate
    assert_equal "Unpaid", internship.pay

    gig = build_post(employment_type: :freelance, paid: false)
    gig.validate
    assert gig.paid?
  end

  test "duration and start date only apply to time-bound posts" do
    gig = build_post(employment_type: :freelance, duration: "2 weeks", starts_on: Date.new(2026, 11, 2))
    gig.validate
    assert_equal "2 weeks · starts 2 Nov 2026", gig.timing

    role = build_post(employment_type: :full_time, duration: "forever", starts_on: Date.current)
    role.validate
    assert_nil role.duration
    assert_nil role.timing
  end

  test "posts group into jobs, gigs and internships" do
    trusted = @company.tap { it.update!(jobs_trusted_at: Time.current) }
    job = create_job!(company: trusted, title: "Engineer")
    gig = create_job!(company: trusted, title: "Logo", employment_type: :freelance)
    intern = create_job!(company: trusted, title: "Intern", employment_type: :internship)

    assert_equal [job], Hiring::JobPost.of_kind(:jobs).to_a
    assert_equal [gig], Hiring::JobPost.of_kind(:gigs).to_a
    assert_equal [intern], Hiring::JobPost.of_kind(:internships).to_a
    assert_equal %w[job gig internship], [job, gig, intern].map(&:kind_noun)
  end

  test "the type can't change once the post exists" do
    post = build_post(employment_type: :freelance)
    post.save!

    post.employment_type = :full_time
    assert_not post.valid?
    assert_includes post.errors[:employment_type], "can't be changed once the post is created"
  end
end
