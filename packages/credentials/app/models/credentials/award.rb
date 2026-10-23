# == Schema Information
#
# Table name: credentials_awards
#
#  id                  :integer          not null, primary key
#  consented_at        :datetime
#  criteria_version    :string           not null
#  evidence_summary    :text             not null
#  expires_at          :datetime
#  issued_at           :datetime
#  recipient_name      :string           not null
#  revoked_at          :datetime
#  revoked_reason      :text
#  status              :integer          default("pending_consent"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  created_by_admin_id :integer          not null
#  definition_id       :integer          not null
#  public_id           :string           not null
#  recipient_id        :integer          not null
#  supersedes_id       :integer
#  updated_by_admin_id :integer
#
# Indexes
#
#  index_credentials_awards_on_created_by_admin_id    (created_by_admin_id)
#  index_credentials_awards_on_current_achievement    (definition_id,recipient_id) UNIQUE WHERE status IN (0, 1)
#  index_credentials_awards_on_definition_id          (definition_id)
#  index_credentials_awards_on_public_id              (public_id) UNIQUE
#  index_credentials_awards_on_recipient_id           (recipient_id)
#  index_credentials_awards_on_status_and_created_at  (status,created_at)
#  index_credentials_awards_on_supersedes_id          (supersedes_id)
#  index_credentials_awards_on_updated_by_admin_id    (updated_by_admin_id)
#
# Foreign Keys
#
#  created_by_admin_id  (created_by_admin_id => admins.id) ON DELETE => restrict
#  definition_id        (definition_id => credentials_definitions.id) ON DELETE => restrict
#  recipient_id         (recipient_id => developers_profiles.id) ON DELETE => restrict
#  supersedes_id        (supersedes_id => credentials_awards.id) ON DELETE => nullify
#  updated_by_admin_id  (updated_by_admin_id => admins.id) ON DELETE => nullify
#
require "securerandom"
require_relative "../credentials"

module Credentials
  class Award < Credentials::ResourceRecord
    LINKEDIN_ADD_TO_PROFILE_URL = "https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME"
    PUBLIC_ID_LENGTH = 24
    PUBLIC_ID_FORMAT = /\A[1-9A-HJ-NP-Za-km-z]{#{PUBLIC_ID_LENGTH}}\z/

    enum :status, {pending_consent: 0, active: 1, expired: 2, revoked: 3}

    belongs_to :definition, class_name: "Credentials::Definition"
    belongs_to :recipient, class_name: "Developers::Profile"
    belongs_to :supersedes, class_name: "Credentials::Award", optional: true
    belongs_to :created_by_admin, class_name: "Admin"
    belongs_to :updated_by_admin, class_name: "Admin", optional: true

    has_many :events, -> { order(created_at: :asc) }, class_name: "Credentials::Event", dependent: :destroy
    has_one :replacement, class_name: "Credentials::Award", foreign_key: :supersedes_id, dependent: :nullify

    before_validation :assign_public_id, on: :create
    before_validation :snapshot_definition, on: :create
    before_validation :snapshot_recipient_name, on: :create

    validates :public_id, presence: true, uniqueness: true,
      format: {with: PUBLIC_ID_FORMAT}
    validates :recipient_name, :evidence_summary, :criteria_version, presence: true
    validates :recipient_id, uniqueness: {
      scope: :definition_id,
      conditions: -> { where(status: %i[pending_consent active]) },
      message: "already has a current credential for this achievement"
    }
    validate :lifecycle_timestamps_match_status

    scope :publicly_verifiable, -> { where(status: %i[active expired revoked]) }
    scope :newest, -> { order(created_at: :desc) }

    def to_param
      public_id
    end

    def publicly_verifiable?
      active? || expired? || revoked?
    end

    def accept!(user:)
      raise ActiveRecord::RecordNotFound unless recipient.user_id == user.id
      raise ActiveRecord::RecordInvalid, self unless pending_consent?

      now = Time.current
      transaction do
        update!(status: :active, consented_at: now, issued_at: now,
          expires_at: definition.expiry_from(now))
        record_event!("consent_recorded", user:, reason: "Recipient accepted public credential issuance")
        record_event!("issued", user:)
      end
      self
    end

    def correct!(attributes, admin:, reason:)
      raise ArgumentError, "A correction reason is required" if reason.blank?

      allowed = attributes.slice(:recipient_name, :evidence_summary, :expires_at)
      before = self.attributes.slice(*allowed.keys.map(&:to_s))
      transaction do
        update!(allowed.merge(updated_by_admin: admin))
        record_event!("corrected", admin:, reason:, changeset: {before:, after: self.attributes.slice(*before.keys)})
      end
      self
    end

    def revoke!(admin:, reason:)
      raise ArgumentError, "A revocation reason is required" if reason.blank?
      raise ActiveRecord::RecordInvalid, self unless active?

      transaction do
        update!(status: :revoked, revoked_at: Time.current, revoked_reason: reason, updated_by_admin: admin)
        record_event!("revoked", admin:, reason:)
      end
      self
    end

    def expire!(admin:, reason:)
      raise ArgumentError, "An expiration reason is required" if reason.blank?
      raise ActiveRecord::RecordInvalid, self unless active?

      transaction do
        update!(status: :expired, expires_at: [expires_at, Time.current].compact.min, updated_by_admin: admin)
        record_event!("expired", admin:, reason:)
      end
      self
    end

    def expire_automatically!
      return self unless active? && expires_at&.past?

      transaction do
        update!(status: :expired)
        record_event!("expired", reason: "Credential reached its configured expiry date")
      end
      self
    end

    def linkedin_fields(verification_url:)
      {
        "Credential name" => definition.name,
        "Issuing organization" => definition.issuing_authority,
        "Issue date" => issued_at&.strftime("%B %Y"),
        "Expiration date" => expires_at&.strftime("%B %Y"),
        "Credential ID" => public_id,
        "Credential URL" => verification_url
      }.compact
    end

    def record_event!(event_type, admin: nil, user: nil, reason: nil, changeset: {})
      events.create!(event_type:, admin:, user:, reason:, changeset:)
    end

    private

    def assign_public_id
      self.public_id ||= loop do
        candidate = SecureRandom.base58(PUBLIC_ID_LENGTH)
        break candidate unless self.class.exists?(public_id: candidate)
      end
    end

    def snapshot_definition
      self.criteria_version ||= definition&.criteria_version
    end

    def snapshot_recipient_name
      self.recipient_name ||= recipient&.name
    end

    def lifecycle_timestamps_match_status
      errors.add(:consented_at, "is required for an issued credential") if active? && consented_at.blank?
      errors.add(:issued_at, "is required for an issued credential") if active? && issued_at.blank?
      errors.add(:revoked_at, "is required for a revoked credential") if revoked? && revoked_at.blank?
      errors.add(:revoked_reason, "is required for a revoked credential") if revoked? && revoked_reason.blank?
    end
  end
end
