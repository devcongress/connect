require "csv"

module AdminPortal
  module Credentials
    class AwardsController < AdminPortal::PlutoniumController
      before_action :set_award, only: %i[show edit update revoke expire reissue]

      def index
        @query = params[:q].to_s.strip
        @status = params[:status].presence
        @awards = ::Credentials::Award.includes(:definition, recipient: :user).newest
        @awards = @awards.where(status: @status) if ::Credentials::Award.statuses.key?(@status)
        if @query.present?
          term = "%#{ActiveRecord::Base.sanitize_sql_like(@query.downcase)}%"
          @awards = @awards.joins(recipient: :user).where(
            "LOWER(credentials_awards.recipient_name) LIKE :term OR " \
            "LOWER(credentials_awards.public_id) LIKE :term OR " \
            "LOWER(developers_profiles.handle) LIKE :term OR " \
            "LOWER(users.email) LIKE :term", term:
          )
        end
      end

      def show
      end

      def new
        @definitions = ::Credentials::Definition.available
        @definition = @definitions.find_by(id: params[:definition_id]) || @definitions.first
      end

      def preview
        @definition = selected_definition
        @profile = find_profile!(credential_params.fetch(:recipient_identifier))
        @award = issuer(@definition).preview(
          profile: @profile,
          evidence_summary: credential_params.fetch(:evidence_summary),
          expires_at: parsed_expiry
        )
        @award.validate
        render :preview, status: (@award.errors.any? ? :unprocessable_content : :ok)
      rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing => error
        redirect_to new_credential_award_path, alert: error.message
      end

      def create
        definition = selected_definition
        profile = find_profile!(credential_params.fetch(:recipient_identifier))
        result = issuer(definition).issue!(
          profile:,
          evidence_summary: credential_params.fetch(:evidence_summary),
          expires_at: parsed_expiry
        )
        notice = result.created ? "Credential invitation created and emailed." : "The existing current credential was reused; no duplicate was created."
        redirect_to credential_award_path(result.award), notice:
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ActionController::ParameterMissing => error
        redirect_to new_credential_award_path, alert: error.message
      end

      def edit
      end

      def update
        @award.correct!(correction_params, admin: current_user, reason: params.require(:reason))
        redirect_to credential_award_path(@award), notice: "Credential details corrected and recorded in the audit trail."
      rescue ArgumentError, ActiveRecord::RecordInvalid, ActionController::ParameterMissing => error
        flash.now[:alert] = error.message
        render :edit, status: :unprocessable_content
      end

      def revoke
        @award.revoke!(admin: current_user, reason: params.require(:reason))
        ::Credentials::CredentialMailer.with(award: @award).revoked.deliver_later
        redirect_to credential_award_path(@award), notice: "Credential revoked. Its verification URL remains available."
      rescue ArgumentError, ActiveRecord::RecordInvalid, ActionController::ParameterMissing => error
        redirect_to credential_award_path(@award), alert: error.message
      end

      def expire
        @award.expire!(admin: current_user, reason: params.require(:reason))
        redirect_to credential_award_path(@award), notice: "Credential marked expired. Its verification URL remains available."
      rescue ArgumentError, ActiveRecord::RecordInvalid, ActionController::ParameterMissing => error
        redirect_to credential_award_path(@award), alert: error.message
      end

      def reissue
        reason = params.require(:reason)
        @award.revoke!(admin: current_user, reason: "Reissued: #{reason}") if @award.active?
        result = issuer(@award.definition).issue!(
          profile: @award.recipient,
          evidence_summary: @award.evidence_summary,
          supersedes: @award
        )
        @award.record_event!("reissued", admin: current_user, reason:, changeset: {replacement_public_id: result.award.public_id})
        redirect_to credential_award_path(result.award), notice: "Replacement credential invitation created."
      rescue ArgumentError, ActiveRecord::RecordInvalid, ActionController::ParameterMissing => error
        redirect_to credential_award_path(@award), alert: error.message
      end

      def batch_new
        @definitions = ::Credentials::Definition.available
      end

      def batch_preview
        @definition = ::Credentials::Definition.available.find(batch_params.fetch(:definition_id))
        @evidence_summary = batch_params.fetch(:evidence_summary)
        identifiers = batch_params.fetch(:recipient_identifiers).lines.map(&:strip).reject(&:blank?).uniq
        @rows = identifiers.map do |identifier|
          profile = find_profile(identifier)
          existing = profile && current_award(@definition, profile)
          {identifier:, profile:, existing:}
        end
        render :batch_preview
      rescue ActionController::ParameterMissing => error
        redirect_to new_credential_batch_path, alert: error.message
      end

      def batch_create
        raise ActionController::BadRequest, "Explicit confirmation is required" unless params[:confirm] == "issue"

        definition = ::Credentials::Definition.available.find(params.require(:definition_id))
        evidence_summary = params.require(:evidence_summary)
        profiles = ::Developers::Profile.where(id: Array(params[:profile_ids]).uniq)
        results = profiles.map { |profile| issuer(definition).issue!(profile:, evidence_summary:) }
        created = results.count(&:created)
        skipped = results.size - created
        redirect_to credential_awards_path,
          notice: "Created #{created} credential #{"invitation".pluralize(created)}; skipped #{skipped} existing #{"credential".pluralize(skipped)}."
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing, ActionController::BadRequest => error
        redirect_to new_credential_batch_path, alert: error.message
      end

      def export
        events = ::Credentials::Event.includes(:admin, :user, award: [:definition, {recipient: :user}]).order(:created_at)
        csv = CSV.generate(headers: true) do |rows|
          rows << %w[event_at event credential_id credential recipient recipient_email status actor reason changes]
          events.each do |event|
            award = event.award
            rows << [event.created_at.iso8601, event.event_type, award.public_id, award.definition.name,
              award.recipient_name, award.recipient.user.email, award.status, event.actor_label,
              event.reason, event.changeset.to_json]
          end
        end
        send_data csv, filename: "devcongress-credential-audit-#{Date.current.iso8601}.csv", type: "text/csv"
      end

      private

      def set_award
        @award = ::Credentials::Award.includes(:definition, :recipient, events: [:admin, :user]).find_by!(public_id: params[:id])
      end

      def selected_definition
        ::Credentials::Definition.available.find(credential_params.fetch(:definition_id))
      end

      def credential_params
        params.require(:credential).permit(:definition_id, :recipient_identifier, :evidence_summary, :expires_at)
      end

      def correction_params
        params.require(:credential).permit(:recipient_name, :evidence_summary, :expires_at)
      end

      def batch_params
        params.require(:batch).permit(:definition_id, :recipient_identifiers, :evidence_summary)
      end

      def parsed_expiry
        credential_params[:expires_at].presence
      end

      def find_profile!(identifier)
        find_profile(identifier) || raise(ActiveRecord::RecordNotFound, "No developer profile matches #{identifier.inspect}")
      end

      def find_profile(identifier)
        value = identifier.to_s.strip.downcase.delete_prefix("@")
        ::Developers::Profile.joins(:user).find_by("LOWER(developers_profiles.handle) = :value OR LOWER(users.email) = :value", value:)
      end

      def current_award(definition, profile)
        ::Credentials::Award.find_by(definition:, recipient: profile, status: %i[pending_consent active])
      end

      def issuer(definition)
        ::Credentials::Issuer.new(definition:, admin: current_user)
      end
    end
  end
end
