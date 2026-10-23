module Credentials
  class Issuer
    Result = Data.define(:award, :created)

    def initialize(definition:, admin:)
      @definition = definition
      @admin = admin
      raise ArgumentError, "This administrator cannot approve #{@definition.name}" unless @definition.approver_roles.include?(@admin.role)
    end

    def preview(profile:, evidence_summary:, expires_at: nil, supersedes: nil)
      Credentials::Award.new(
        definition: @definition,
        recipient: profile,
        recipient_name: profile.name,
        evidence_summary:,
        expires_at:,
        supersedes:,
        created_by_admin: @admin
      )
    end

    def issue!(profile:, evidence_summary:, expires_at: nil, supersedes: nil, notify: true)
      current = current_award_for(profile)
      return Result.new(current, false) if current

      award = preview(profile:, evidence_summary:, expires_at:, supersedes:)
      Credentials::Award.transaction do
        award.save!
        award.record_event!("invitation_created", admin: @admin,
          reason: "Evidence reviewed against criteria #{award.criteria_version}")
      end
      Credentials::CredentialMailer.with(award:).invitation.deliver_later if notify
      Result.new(award, true)
    rescue ActiveRecord::RecordNotUnique
      Result.new(current_award_for(profile), false)
    end

    private

    def current_award_for(profile)
      Credentials::Award.find_by(
        definition: @definition,
        recipient: profile,
        status: %i[pending_consent active]
      )
    end
  end
end
