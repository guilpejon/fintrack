require "test_helper"

class Investments::FetchPriceJobTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  def stub_httparty(response_obj)
    original = HTTParty.method(:get)
    HTTParty.define_singleton_method(:get) { |*| response_obj }
    original
  end

  def fake_response(success:, body: {})
    r = Object.new
    r.define_singleton_method(:success?) { success }
    r.define_singleton_method(:parsed_response) { body }
    r.define_singleton_method(:code) { success ? 200 : 500 }
    r
  end

  test "updates current_price for stock investments on success" do
    investment = create(:investment, user: @user, ticker: "PETR4", investment_type: "stock", current_price: 30.0)
    body = { "results" => [ { "regularMarketPrice" => 35.50 } ] }
    original = stub_httparty(fake_response(success: true, body: body))

    Investments::FetchPriceJob.new.perform("PETR4", "stock")

    assert_in_delta 35.50, investment.reload.current_price, 0.01
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "updates current_price for crypto investments on success" do
    investment = create(:investment, user: @user, ticker: "bitcoin", investment_type: "crypto", current_price: 100_000.0)
    body = { "bitcoin" => { "brl" => 550_000.0 } }
    original = stub_httparty(fake_response(success: true, body: body))

    Investments::FetchPriceJob.new.perform("bitcoin", "crypto")

    assert_in_delta 550_000.0, investment.reload.current_price, 0.01
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "does not update price when stock HTTP response fails" do
    investment = create(:investment, user: @user, ticker: "FAIL4", investment_type: "stock", current_price: 10.0)
    original = stub_httparty(fake_response(success: false))

    Investments::FetchPriceJob.new.perform("FAIL4", "stock")

    assert_in_delta 10.0, investment.reload.current_price, 0.01
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "does not update price when crypto HTTP response fails" do
    investment = create(:investment, user: @user, ticker: "ethereum", investment_type: "crypto", current_price: 5000.0)
    original = stub_httparty(fake_response(success: false))

    Investments::FetchPriceJob.new.perform("ethereum", "crypto")

    assert_in_delta 5000.0, investment.reload.current_price, 0.01
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "does not update price when stock returns zero" do
    investment = create(:investment, user: @user, ticker: "ZERO3", investment_type: "stock", current_price: 10.0)
    body = { "results" => [ { "regularMarketPrice" => 0 } ] }
    original = stub_httparty(fake_response(success: true, body: body))

    Investments::FetchPriceJob.new.perform("ZERO3", "stock")

    assert_in_delta 10.0, investment.reload.current_price, 0.01
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "updates last_price_update_at on successful price fetch" do
    investment = create(:investment, user: @user, ticker: "ITUB4", investment_type: "stock", last_price_update_at: nil)
    body = { "results" => [ { "regularMarketPrice" => 25.0 } ] }
    original = stub_httparty(fake_response(success: true, body: body))

    Investments::FetchPriceJob.new.perform("ITUB4", "stock")

    assert_not_nil investment.reload.last_price_update_at
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "rescues StandardError without re-raising" do
    original = HTTParty.method(:get)
    HTTParty.define_singleton_method(:get) { |*| raise StandardError, "network error" }

    assert_nothing_raised { Investments::FetchPriceJob.new.perform("PETR4", "stock") }
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "does nothing for unknown investment type" do
    investment = create(:investment, user: @user, ticker: "XYZ", investment_type: "fund", current_price: 100.0)

    assert_nothing_raised { Investments::FetchPriceJob.new.perform("XYZ", "fund") }
    assert_in_delta 100.0, investment.reload.current_price, 0.01
  end
end
