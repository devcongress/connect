module DeveloperPortal
  module Credentials
    class AwardsController < DeveloperPortal::PlutoniumController
      before_action :set_profile
      before_action :set_award, only: %i[show accept]

      def index
        @awards = @profile.credential_awards.includes(:definition).newest
      end

      def show
      end

      def accept
        @award.accept!(user: current_user)
        ::Credentials::CredentialMailer.with(award: @award).issued.deliver_later
        redirect_to main_app.public_credential_path(@award.public_id), notice: "Credential accepted and issued. Your verification page is now public."
      rescue ActiveRecord::RecordInvalid => error
        redirect_to developers_profile_scoped_credential_award_path(developers_profile_scoped: @profile, id: @award.public_id), alert: error.message
      end

      private

      def set_profile
        @profile = current_scoped_entity
      end

      def set_award
        @award = @profile.credential_awards.includes(:definition).find_by!(public_id: params[:id])
      end
    end
  end
end
