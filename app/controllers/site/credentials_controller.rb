module Site
  class CredentialsController < BaseController
    before_action :set_award

    def show
    end

    def badge
      @theme = (params[:theme] == "dark") ? "dark" : "light"
      response.headers["Content-Disposition"] = %(inline; filename="#{@award.definition.slug}-badge-#{@theme}.svg")
      render formats: :svg, content_type: "image/svg+xml"
    end

    def certificate
      response.headers["Content-Disposition"] = %(attachment; filename="#{@award.definition.slug}-#{@award.public_id}.svg")
      render formats: :svg, content_type: "image/svg+xml"
    end

    private

    def set_award
      @award = ::Credentials::Award.publicly_verifiable.includes(:definition, recipient: :user).find_by!(public_id: params[:id])
    end
  end
end
