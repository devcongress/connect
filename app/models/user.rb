# == Schema Information
#
# Table name: users
#
#  id            :integer          not null, primary key
#  email         :string           not null
#  password_hash :string
#  status        :integer          default("unverified"), not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE WHERE status IN (1, 2)
#
class User < ResourceRecord
  include Rodauth::Rails.model(:user)

  # add concerns above.

  # add constants above.

  enum :status, unverified: 1, verified: 2, closed: 3
  # add enums above.

  # add model configurations above.

  # add belongs_to associations above.

  has_one :developer_profile, class_name: "Developers::Profile", dependent: :destroy
  # add has_one associations above.
  has_many :company_users, dependent: :destroy
  has_many :companies, through: :company_users
  has_many :notification_opt_outs, dependent: :delete_all

  # add has_many associations above.

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

  # Onboarded users have a developer profile, a company, or both.
  def onboarded?
    developer_profile.present? || company_users.exists?
  end

  # Categorised notifications (see NotificationOptOut::CATEGORIES) are on in
  # each channel until turned off.
  def wants_notification?(category, via:)
    !notification_opt_outs.exists?(channel: via.to_s, category: category.to_s)
  end

  def opt_out!(category, via:)
    notification_opt_outs.create_or_find_by!(channel: via.to_s, category: category.to_s)
  end

  # Turns off exactly these categories in one channel and turns the rest back on.
  def update_opt_outs!(categories, via:)
    transaction do
      notification_opt_outs.where(channel: via.to_s).where.not(category: categories).delete_all
      categories.each { opt_out!(it, via:) }
    end
    notification_opt_outs.reset
  end

  def slack_identity
    identities.find_by(provider: "slack")
  end

  # Slack DMs take over from email. People can turn email back on per category.
  def slack_connected!
    NotificationOptOut::CATEGORIES.each_key { opt_out!(it, via: :email) }
  end

  # Email comes back for every category still on in Slack, so nobody stops
  # hearing about something they wanted. Slack opt-outs stay in case they reconnect.
  def disconnect_slack!
    transaction do
      slack_identity.destroy!
      still_on = NotificationOptOut::CATEGORIES.keys.select { wants_notification?(it, via: :slack) }
      notification_opt_outs.where(channel: "email", category: still_on).delete_all
    end
  end

  def can_sign_in_without_slack?
    password_hash.present? || identities.where.not(provider: "slack").exists?
  end

  # add methods above. add private methods below.
end
