require "test_helper"

class CredentialsExpiryJobTest < ActiveJob::TestCase
  include AccountsTestHelper

  test "expires active credentials after their configured expiry" do
    due = create_credential_award!(status: :active, expires_at: 1.minute.ago)
    future = create_credential_award!(status: :active, expires_at: 1.day.from_now)

    Credentials::ExpiryJob.perform_now

    assert due.reload.expired?
    assert future.reload.active?
    assert_equal "Credential reached its configured expiry date", due.events.last.reason
  end
end
