require "test_helper"

class PublicCredentialsTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @definition = create_credential_definition!(slug: "community-contributor")
    @profile = create_profile!(name: "Ama Mensah")
    @admin = Admin.create!(email: "admin@example.com", status: :verified)
  end

  test "pending credentials are private" do
    award = create_credential_award!(profile: @profile, definition: @definition, admin: @admin)

    get "/credentials/#{award.public_id}"
    assert_response :not_found
    get "/credentials/#{award.public_id}/badge.svg"
    assert_response :not_found
  end

  test "active credential publishes minimum verification details and LinkedIn instructions" do
    award = create_credential_award!(profile: @profile, definition: @definition, admin: @admin, status: :active)

    get "/credentials/#{award.public_id}"

    assert_response :success
    assert_select "h1", @definition.name
    assert_includes response.body, "Ama Mensah"
    assert_includes response.body, award.public_id
    assert_includes response.body, "Add to LinkedIn"
    assert_select "a[href=?]", Credentials::Award::LINKEDIN_ADD_TO_PROFILE_URL
    assert_not_includes response.body, @profile.user.email
    assert_includes response.body, "does not create a LinkedIn verification badge"
    assert_includes response.body, "EducationalOccupationalCredential"
  end

  test "revoked and expired credentials stay resolvable with their status" do
    revoked = create_credential_award!(profile: @profile, definition: @definition, admin: @admin, status: :active)
    revoked.revoke!(admin: @admin, reason: "Evidence invalidated")
    expired = create_credential_award!(profile: create_profile!(name: "Kojo Owusu"), definition: @definition, admin: @admin, status: :active)
    expired.expire!(admin: @admin, reason: "Program ended")

    get "/credentials/#{revoked.public_id}"
    assert_response :success
    assert_includes response.body, "Evidence invalidated"

    get "/credentials/#{expired.public_id}"
    assert_response :success
    assert_includes response.body, "expired"
  end

  test "badge and certificate are downloadable SVG assets" do
    award = create_credential_award!(profile: @profile, definition: @definition, admin: @admin, status: :active)

    get "/credentials/#{award.public_id}/badge.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_includes response.body, @definition.badge_alt_text

    get "/credentials/#{award.public_id}/certificate.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.body, @profile.name
  end
end
