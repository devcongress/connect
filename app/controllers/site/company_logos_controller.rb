module Site
  class CompanyLogosController < BaseController
    def show
      company = Company.organizations.find_by!(slug: params[:slug])
      attachment = company.logo.attachment
      raise ActiveRecord::RecordNotFound unless attachment&.file

      response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
      attachment.file.open do |io|
        send_data io.read,
          filename: attachment.filename.presence || "company-logo.#{attachment.extension}",
          type: attachment.content_type,
          disposition: :inline
      end
    end
  end
end
