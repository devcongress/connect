module Credentials
  class CredentialMailer < ::ApplicationMailer
    prepend_view_path Credentials::Engine.root.join("app/views")

    before_action do
      @award = params[:award]
      @profile = @award.recipient
      @definition = @award.definition
    end

    def invitation
      @credential_url = absolute_url("/developer/#{@profile.to_param}/credentials/#{@award.public_id}")
      mail to: @profile.user.email, subject: "Review your #{@definition.name} credential"
    end

    def issued
      @verification_url = absolute_url("/credentials/#{@award.public_id}")
      mail to: @profile.user.email, subject: "Your #{@definition.name} credential is ready"
    end

    def revoked
      @verification_url = absolute_url("/credentials/#{@award.public_id}")
      mail to: @profile.user.email, subject: "Update to your #{@definition.name} credential"
    end
  end
end
