require "test_helper"

class BankAccounts::UpdateDailyInterestJobTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @original_business_day = BrazilianHolidays.method(:business_day?)
  end

  teardown do
    BrazilianHolidays.define_singleton_method(:business_day?, &@original_business_day)
  end

  test "applies interest to accounts with fixed rate on business days" do
    account = create(:bank_account, user: @user, balance: 10000.0, interest_rate: 12.0, rate_type: "fixed")
    BrazilianHolidays.define_singleton_method(:business_day?) { |*| true }

    BankAccounts::UpdateDailyInterestJob.new.perform

    assert account.reload.balance > 10000.0
  end

  test "applies interest to CDI-based accounts on business days" do
    account = create(:bank_account, :cdi, user: @user, balance: 10000.0)
    BrazilianHolidays.define_singleton_method(:business_day?) { |*| true }
    original_cdi = CdiRate.method(:current)
    CdiRate.define_singleton_method(:current) { 12.5 }

    BankAccounts::UpdateDailyInterestJob.new.perform

    assert account.reload.balance > 10000.0
  ensure
    CdiRate.define_singleton_method(:current, &original_cdi)
  end

  test "does not apply interest on non-business days" do
    account = create(:bank_account, user: @user, balance: 10000.0, interest_rate: 12.0, rate_type: "fixed")
    original_balance = account.balance
    BrazilianHolidays.define_singleton_method(:business_day?) { |*| false }

    BankAccounts::UpdateDailyInterestJob.new.perform

    assert_equal original_balance, account.reload.balance
  end

  test "skips accounts with zero interest rate and fixed type" do
    account = create(:bank_account, user: @user, balance: 5000.0, interest_rate: 0.0, rate_type: "fixed")
    BrazilianHolidays.define_singleton_method(:business_day?) { |*| true }

    BankAccounts::UpdateDailyInterestJob.new.perform

    assert_equal 5000.0, account.reload.balance
  end

  test "rescues errors without re-raising" do
    BrazilianHolidays.define_singleton_method(:business_day?) { |*| raise StandardError, "unexpected" }

    assert_nothing_raised { BankAccounts::UpdateDailyInterestJob.new.perform }
  end
end
