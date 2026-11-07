# One developer following a company. Company follows are deliberately separate
# from developer follows: they do not create connections or grant access to
# connection-only profile details.
require_relative "../network"

class Network::CompanyFollow < Network::ResourceRecord
  belongs_to :follower, class_name: "Developers::Profile", inverse_of: :company_follows
  belongs_to :company, inverse_of: :company_follows

  scope :newest, -> { order(created_at: :desc) }

  validates :company, uniqueness: {scope: :follower_id, message: "is already followed"}

  def to_label
    "#{follower&.name} follows #{company&.display_name}"
  end
end
