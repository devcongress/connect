# == Schema Information
#
# Table name: credentials_definitions
#
#  id                    :integer          not null, primary key
#  active                :boolean          default(TRUE), not null
#  approver_roles        :json             not null
#  badge_alt_text        :string           not null
#  criteria_version      :string           not null
#  description           :text             not null
#  does_not_prove        :text             not null
#  eligibility_criteria  :text             not null
#  evidence_requirements :text             not null
#  expires_after_months  :integer
#  issuing_authority     :string           default("DevCongress"), not null
#  lifecycle_rules       :text             not null
#  name                  :string           not null
#  short_description     :string           not null
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_credentials_definitions_on_slug  (slug) UNIQUE
#
require_relative "../credentials"

module Credentials
  class Definition < Credentials::ResourceRecord
    has_many :awards, class_name: "Credentials::Award", dependent: :restrict_with_error

    scope :available, -> { where(active: true).order(:name) }

    validates :name, :slug, :short_description, :description, :eligibility_criteria,
      :evidence_requirements, :issuing_authority, :criteria_version, :lifecycle_rules,
      :does_not_prove, :badge_alt_text, presence: true
    validates :slug, uniqueness: true, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}
    validates :expires_after_months, numericality: {only_integer: true, greater_than: 0}, allow_nil: true

    normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase.parameterize }

    def expiry_from(time)
      expires_after_months&.months&.after(time)
    end

    def to_label
      name
    end
  end
end
