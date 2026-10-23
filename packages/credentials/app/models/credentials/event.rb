# == Schema Information
#
# Table name: credentials_events
#
#  id         :integer          not null, primary key
#  changeset  :json             not null
#  event_type :string           not null
#  reason     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  admin_id   :integer
#  award_id   :integer          not null
#  user_id    :integer
#
# Indexes
#
#  index_credentials_events_on_admin_id                   (admin_id)
#  index_credentials_events_on_award_id                   (award_id)
#  index_credentials_events_on_award_id_and_created_at    (award_id,created_at)
#  index_credentials_events_on_event_type_and_created_at  (event_type,created_at)
#  index_credentials_events_on_user_id                    (user_id)
#
# Foreign Keys
#
#  admin_id  (admin_id => admins.id) ON DELETE => nullify
#  award_id  (award_id => credentials_awards.id) ON DELETE => cascade
#  user_id   (user_id => users.id) ON DELETE => nullify
#
require_relative "../credentials"

module Credentials
  class Event < Credentials::ResourceRecord
    belongs_to :award, class_name: "Credentials::Award"
    belongs_to :admin, optional: true
    belongs_to :user, optional: true

    validates :event_type, presence: true

    def actor_label
      admin&.email || user&.email || "System"
    end
  end
end
