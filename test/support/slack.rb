module Slack
  # Records API calls instead of making them. fail_next makes the next call to
  # a method raise the given Slack error code.
  class FakeClient
    Call = Struct.new(:method, :params)

    attr_reader :calls

    def initialize
      @calls = []
      @failures = {}
      @sequence = 0
    end

    def fail_next(method, code)
      @failures[method] = code
    end

    def post_message(**params)
      record(:post_message, params)
      {"ok" => true, "ts" => "1700000000.#{format("%06d", @sequence += 1)}", "channel" => params[:channel]}
    end

    def update_message(**params)
      record(:update_message, params)
      {"ok" => true, "ts" => params[:ts]}
    end

    def permalink(channel:, ts:)
      record(:permalink, {channel:, ts:})
      "https://devcongress-community.slack.com/archives/#{channel}/p#{ts.delete(".")}"
    end

    def calls_to(method) = calls.select { it.method == method }

    private

    def record(method, params)
      code = @failures.delete(method)
      raise Slack::Error.new(code) if code

      @calls << Call.new(method, params)
    end
  end
end

# Swaps in the fake client and a #jobs channel for the test.
module SlackTestHelper
  def self.included(base)
    base.setup do
      @slack = Slack::FakeClient.new
      Slack.client = @slack
      Slack.jobs_channel = "C0JOBS"
    end
    base.teardown do
      Slack.client = nil
      Slack.jobs_channel = nil
    end
  end
end

# Drops the Slack sign-in provider (registered from .env.test.local) for the
# block, as when SLACK_CLIENT_ID and friends aren't set.
module SlackSignInTestHelper
  def without_slack_sign_in
    auth = RodauthApp.rodauth(:user)
    providers = auth.instance_variable_get(:@omniauth_providers)
    auth.instance_variable_set(:@omniauth_providers, providers.reject { |(_, *args)| args.last.is_a?(Hash) && args.last[:name] == :slack })
    yield
  ensure
    auth.instance_variable_set(:@omniauth_providers, providers)
  end
end
