module AccountsTestHelper
  def create_user!(email: "dev#{SecureRandom.hex(4)}@example.com")
    User.create!(email:, status: :verified, password_hash: BCrypt::Password.create("password123"))
  end

  def create_profile!(user: create_user!, name: "Ada Lovelace", **attributes)
    first_name, other_names = name.split(" ", 2)
    user.create_developer_profile!(first_name:, other_names:, handle: "ada-#{SecureRandom.hex(3)}", **attributes)
  end

  def create_company!(owner: nil, name: "Company #{SecureRandom.hex(3)}")
    Company.create!(name:).tap do |company|
      company.company_users.create!(user: owner, role: :owner) if owner
    end
  end

  def create_credential_definition!(**attributes)
    Credentials::Definition.create!({
      name: "DevCongress Community Contributor",
      slug: "community-contributor-#{SecureRandom.hex(3)}",
      short_description: "Recognizes a reviewed contribution to the DevCongress community.",
      description: "Awarded after DevCongress reviews a completed contribution with a concrete community outcome.",
      eligibility_criteria: "Complete an accepted contribution with a concrete outcome for a DevCongress program, event, project, or resource.",
      evidence_requirements: "A first-party project, event, program, or organizer record reviewed by an authorized administrator.",
      issuing_authority: "DevCongress",
      approver_roles: %w[super_admin admin],
      criteria_version: "1.0",
      lifecycle_rules: "Does not expire. Corrections, revocations, and reissues require a recorded reason.",
      does_not_prove: "This is not employment, a degree, professional licensure, identity verification, or LinkedIn endorsement.",
      badge_alt_text: "DevCongress Community Contributor credential badge"
    }.merge(attributes))
  end

  def create_credential_award!(profile: create_profile!, definition: create_credential_definition!, admin: nil, status: :pending_consent, **attributes)
    admin ||= Admin.create!(email: "admin-#{SecureRandom.hex(3)}@example.com", status: :verified)
    timestamps = (status.to_sym == :active) ? {consented_at: Time.current, issued_at: Time.current} : {}
    Credentials::Award.create!({
      definition:,
      recipient: profile,
      evidence_summary: "Reviewed contribution record DC-123.",
      created_by_admin: admin,
      status:
    }.merge(timestamps).merge(attributes))
  end

  # Published jobs are approved too unless review: true (first-job review).
  def create_job!(company:, published: true, review: false, **attributes)
    job = company.job_posts.create!(title: "Backend Engineer", description: "Build things.", **attributes)
    return job unless published

    company.update!(jobs_trusted_at: Time.current) unless review || company.jobs_trusted?
    job.publish!
    job
  end

  # Logs in and follows the post-login redirects (/welcome checks for invites first).
  def login_user(user)
    login_as(user, portal: :user)
    follow_redirect! while response.redirect?
  end
end
