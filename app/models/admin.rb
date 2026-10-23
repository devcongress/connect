# == Schema Information
#
# Table name: admins
#
#  id            :integer          not null, primary key
#  email         :string           not null
#  password_hash :string
#  role          :integer          default("super_admin"), not null
#  status        :integer          default("unverified"), not null
#
# Indexes
#
#  index_admins_on_email  (email) UNIQUE WHERE status IN (1, 2)
#
class Admin < ResourceRecord
  include Rodauth::Rails.model(:admin)

  # add concerns above.

  # add constants above.

  enum :status, unverified: 1, verified: 2, closed: 3
  enum :role, super_admin: 0, admin: 1
  # add enums above.

  # add model configurations above.

  # add belongs_to associations above.

  # add has_one associations above.

  # add has_many associations above.
  has_many :created_credential_awards, class_name: "Credentials::Award", foreign_key: :created_by_admin_id, dependent: :restrict_with_error
  has_many :credential_events, class_name: "Credentials::Event", dependent: :nullify

  # add attachments above.

  # add scopes above.

  validates :email, presence: true
  # add validations above.

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    email
  end

  # add methods above. add private methods below.
end
