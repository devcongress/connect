require "openssl"

# Produces a stable, unpredictable ordering for a set of record IDs each day.
# The ordering survives refreshes and server restarts, but intentionally changes
# when the eligible IDs change or a new daily period begins.
class DeterministicDailyOrder
  DIGEST = "SHA256"

  def self.call(ids, context:, period: Date.current, secret: Rails.application.secret_key_base)
    period_key = period.to_date.iso8601

    ids.sort_by do |id|
      digest = OpenSSL::HMAC.hexdigest(DIGEST, secret, "#{context}:#{period_key}:#{id}")
      [digest, id]
    end
  end
end
