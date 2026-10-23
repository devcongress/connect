require "test_helper"

class CredentialsAwardTest < ActiveSupport::TestCase
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @profile = create_profile!
    @definition = create_credential_definition!
    @admin = Admin.create!(email: "admin@example.com", status: :verified)
    @issuer = Credentials::Issuer.new(definition: @definition, admin: @admin)
  end

  test "issuance is idempotent for a current achievement" do
    assert_enqueued_emails 1 do
      first = @issuer.issue!(profile: @profile, evidence_summary: "Reviewed contribution DC-1")
      duplicate = @issuer.issue!(profile: @profile, evidence_summary: "Reviewed contribution DC-1")

      assert first.created
      assert_not duplicate.created
      assert_equal first.award, duplicate.award
    end

    assert_equal 1, Credentials::Award.count
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{24}\z/, Credentials::Award.first.public_id)
  end

  test "issuance requires evidence that supports the credential" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      @issuer.issue!(profile: @profile, evidence_summary: "", notify: false)
    end

    assert_includes error.record.errors[:evidence_summary], "can't be blank"
    assert_empty Credentials::Award.where(recipient: @profile)
  end

  test "issuance enforces the definition's approver roles" do
    restricted_definition = create_credential_definition!(approver_roles: %w[super_admin])
    regular_admin = Admin.create!(email: "reviewer@example.com", status: :verified, role: :admin)

    error = assert_raises(ArgumentError) do
      Credentials::Issuer.new(definition: restricted_definition, admin: regular_admin)
    end

    assert_match(/cannot approve/, error.message)
  end

  test "only the recipient can consent and issue the credential" do
    award = @issuer.issue!(profile: @profile, evidence_summary: "Reviewed contribution DC-2", notify: false).award

    assert_raises(ActiveRecord::RecordNotFound) { award.accept!(user: create_user!) }
    award.accept!(user: @profile.user)

    assert award.active?
    assert award.consented_at
    assert award.issued_at
    assert_equal %w[invitation_created consent_recorded issued], award.events.pluck(:event_type)
  end

  test "duplicate active credentials are prevented at model and database levels" do
    award = @issuer.issue!(profile: @profile, evidence_summary: "Reviewed contribution DC-3", notify: false).award
    award.accept!(user: @profile.user)

    duplicate = Credentials::Award.new(
      definition: @definition,
      recipient: @profile,
      evidence_summary: "Duplicate",
      created_by_admin: @admin,
      status: :active,
      consented_at: Time.current,
      issued_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:recipient_id], "already has a current credential for this achievement"
  end

  test "correction revocation expiry and reissue are auditable" do
    award = create_credential_award!(profile: @profile, definition: @definition, admin: @admin, status: :active)
    award.record_event!("issued", admin: @admin)

    award.correct!({recipient_name: "Ada B. Lovelace"}, admin: @admin, reason: "Correct legal display name")
    award.revoke!(admin: @admin, reason: "Evidence was withdrawn")
    replacement = @issuer.issue!(profile: @profile, evidence_summary: award.evidence_summary, supersedes: award, notify: false).award
    award.record_event!("reissued", admin: @admin, reason: "Issue corrected record")

    assert award.revoked?
    assert_equal award, replacement.supersedes
    assert_equal %w[issued corrected revoked reissued], award.events.pluck(:event_type)
    assert_equal "Ada B. Lovelace", award.recipient_name
  end

  test "an active credential can be expired with a reason" do
    award = create_credential_award!(profile: @profile, definition: @definition, admin: @admin, status: :active)
    award.expire!(admin: @admin, reason: "Time-limited program ended")

    assert award.expired?
    assert award.expires_at
    assert_equal "Time-limited program ended", award.events.last.reason
  end
end
