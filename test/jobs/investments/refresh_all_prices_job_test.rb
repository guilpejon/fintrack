require "test_helper"

class Investments::RefreshAllPricesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  test "enqueues FetchPriceJob for each distinct ticker" do
    create(:investment, user: @user, ticker: "PETR4", investment_type: "stock")
    create(:investment, user: @user, ticker: "ITUB4", investment_type: "stock")

    assert_enqueued_jobs 2, only: Investments::FetchPriceJob do
      Investments::RefreshAllPricesJob.new.perform
    end
  end

  test "does not enqueue job for investments without a ticker" do
    create(:investment, user: @user, ticker: nil)
    create(:investment, user: @user, ticker: "")

    assert_no_enqueued_jobs only: Investments::FetchPriceJob do
      Investments::RefreshAllPricesJob.new.perform
    end
  end

  test "enqueues only one job per distinct ticker even with duplicates" do
    create(:investment, user: @user, ticker: "PETR4", investment_type: "stock")
    create(:investment, user: @user, ticker: "PETR4", investment_type: "stock")

    assert_enqueued_jobs 1, only: Investments::FetchPriceJob do
      Investments::RefreshAllPricesJob.new.perform
    end
  end

  test "rescues StandardError without re-raising" do
    # Simulate an error during job enqueue
    original = Investments::FetchPriceJob.method(:perform_later)
    Investments::FetchPriceJob.define_singleton_method(:perform_later) { |*| raise StandardError, "queue error" }

    create(:investment, user: @user, ticker: "PETR4", investment_type: "stock")
    assert_nothing_raised { Investments::RefreshAllPricesJob.new.perform }
  ensure
    Investments::FetchPriceJob.define_singleton_method(:perform_later, &original)
  end
end
