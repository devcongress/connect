# Company logos displayed on public company profiles. SVG is deliberately not
# accepted because serving user-authored SVG inline can execute active content.
class CompanyLogoUploader < Shrine
  MAX_SIZE = 5.megabytes
  TYPES = {
    "image/jpeg" => ".jpg",
    "image/png" => ".png",
    "image/webp" => ".webp"
  }.freeze

  plugin :validation_helpers

  Attacher.validate do
    validate_max_size MAX_SIZE, message: "must be 5 MB or smaller"
    validate_mime_type TYPES.keys, message: "must be a JPG, PNG or WebP image"
  end

  # The shared upload store is private. Company logos are the exception: their
  # stable URL goes through a controller that exposes only this public asset.
  class Attacher < Shrine::Attacher
    def url(**)
      company = record&.record
      return super unless company.is_a?(Company) && company.persisted? && record.persisted?

      Rails.application.routes.url_helpers.public_company_logo_path(
        slug: company.slug,
        v: record.updated_at.to_i
      )
    end
  end
end
