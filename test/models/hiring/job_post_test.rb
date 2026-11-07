require "test_helper"

class Hiring::JobPostTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @company = create_company!.tap { it.update!(jobs_trusted_at: Time.current) } }

  test "moves through draft, active, expired, filled and archived" do
    job = create_job!(company: @company, published: false)
    assert_equal :draft, job.status
    assert_not Hiring::JobPost.active.include?(job)

    job.publish!
    assert_equal :active, job.status
    assert_in_delta Hiring::JobPost::VALIDITY_PERIOD.from_now, job.expires_at, 5
    assert Hiring::JobPost.active.include?(job)

    job.update!(expires_at: 1.day.ago)
    assert_equal :expired, job.status
    assert job.renewable?
    job.renew!
    assert_equal :active, job.status

    job.mark_filled!
    assert_equal :filled, job.status
    assert_not Hiring::JobPost.active.include?(job)
    job.reopen!
    assert_equal :active, job.status

    job.archive!
    assert_equal :archived, job.status
  end

  test "needs a way to apply" do
    job = @company.job_posts.build(title: "Dev", description: "x", accepts_applications: false)
    assert_not job.valid?

    job.apply_url = "https://acme.test/careers"
    assert job.valid?
  end

  test "salary range must be in order" do
    job = @company.job_posts.build(title: "Dev", description: "x", salary_min: 100, salary_max: 50)
    assert_not job.valid?
    assert job.errors[:salary_max].any?
  end
end
