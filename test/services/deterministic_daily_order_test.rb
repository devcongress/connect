require "test_helper"

class DeterministicDailyOrderTest < ActiveSupport::TestCase
  IDS = (1..8).to_a
  PERIOD = Date.new(2026, 10, 19)
  TEST_SECRET = "deterministic-daily-order-test-secret"

  test "is stable for a period and uses a different deterministic order later" do
    first = order_for(PERIOD)
    repeated = order_for(PERIOD)
    next_period = order_for(PERIOD + 1)
    repeated_next_period = order_for(PERIOD + 1)

    assert_equal first, repeated
    assert_equal next_period, repeated_next_period
    refute_equal first, next_period
  end

  private

  def order_for(period)
    DeterministicDailyOrder.call(IDS, context: "test", period:, secret: TEST_SECRET)
  end
end
