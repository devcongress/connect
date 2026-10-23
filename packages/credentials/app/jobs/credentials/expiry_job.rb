module Credentials
  class ExpiryJob < ApplicationJob
    queue_as :default

    def perform
      Credentials::Award.active.where(expires_at: ..Time.current).find_each(&:expire_automatically!)
    end
  end
end
