require "test_helper"

class CredentialWorkflowTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @definition = create_credential_definition!
    @profile = create_profile!(name: "Ama Mensah")
    @admin = Admin.create!(email: "admin@example.com", status: :verified, password_hash: BCrypt::Password.create("password123"))
  end

  test "admin preview is a dry run and creation sends one consent invitation" do
    login_as(@admin, portal: :admin)

    assert_no_difference("Credentials::Award.count") do
      assert_no_enqueued_emails do
        post "/admin/credentials/preview", params: {credential: {
          definition_id: @definition.id,
          recipient_identifier: @profile.handle,
          evidence_summary: "Reviewed program contribution DC-44"
        }}
      end
    end
    assert_response :success
    assert_includes response.body, "No credential exists yet"

    assert_difference("Credentials::Award.count", 1) do
      assert_enqueued_emails 1 do
        post "/admin/credentials", params: {credential: {
          definition_id: @definition.id,
          recipient_identifier: @profile.handle,
          evidence_summary: "Reviewed program contribution DC-44"
        }}
      end
    end
    assert_redirected_to %r{/admin/credentials/}

    assert_no_difference("Credentials::Award.count") do
      assert_no_enqueued_emails do
        post "/admin/credentials", params: {credential: {
          definition_id: @definition.id,
          recipient_identifier: @profile.handle,
          evidence_summary: "Reviewed program contribution DC-44"
        }}
      end
    end
  end

  test "recipient sees invitation and explicitly consents before publication" do
    award = Credentials::Issuer.new(definition: @definition, admin: @admin).issue!(
      profile: @profile,
      evidence_summary: "Reviewed project contribution",
      notify: false
    ).award
    login_user(@profile.user)

    get "/developer/#{@profile.handle}/credentials/#{award.public_id}"
    assert_response :success
    assert_includes response.body, "Nothing becomes public"

    assert_enqueued_emails 1 do
      post "/developer/#{@profile.handle}/credentials/#{award.public_id}/accept"
    end
    assert_redirected_to "/credentials/#{award.public_id}"
    assert award.reload.active?
  end

  test "batch preview creates no credentials and sends no notifications" do
    login_as(@admin, portal: :admin)

    assert_no_difference("Credentials::Award.count") do
      assert_no_enqueued_emails do
        post "/admin/credentials/batch/preview", params: {batch: {
          definition_id: @definition.id,
          recipient_identifiers: "#{@profile.handle}\nmissing@example.com",
          evidence_summary: "Reviewed cohort contribution records"
        }}
      end
    end

    assert_response :success
    assert_includes response.body, "1 of 2 recipients"
    assert_includes response.body, "No matching profile"
  end

  test "unauthenticated users cannot access credential administration" do
    get "/admin/credentials"
    assert_response :redirect

    get "/developer/#{@profile.handle}/credentials"
    assert_response :redirect
  end
end
