require "test_helper"

class InvestmentTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    investment = build(:investment)
    assert investment.valid?
  end

  test "requires name" do
    investment = build(:investment, name: nil)
    assert_not investment.valid?
    assert investment.errors[:name].any?
  end

  test "requires valid investment_type" do
    investment = build(:investment, investment_type: "invalid")
    assert_not investment.valid?
  end

  test "accepts all valid investment types" do
    %w[stock crypto fund].each do |type|
      investment = build(:investment, investment_type: type)
      assert investment.valid?, "Expected #{type} to be valid"
    end
  end

  test "requires quantity >= 0" do
    investment = build(:investment, quantity: -1)
    assert_not investment.valid?

    investment2 = build(:investment, quantity: 0)
    assert investment2.valid?
  end

  test "requires average_price >= 0" do
    investment = build(:investment, average_price: -1)
    assert_not investment.valid?

    investment2 = build(:investment, average_price: 0)
    assert investment2.valid?
  end

  test "total_invested returns quantity times average_price" do
    investment = build(:investment, quantity: 10.0, average_price: 50.0)
    assert_equal 500.0, investment.total_invested
  end

  test "current_value returns quantity times current_price" do
    investment = build(:investment, quantity: 10.0, current_price: 60.0)
    assert_equal 600.0, investment.current_value
  end

  test "profit_loss returns current_value minus total_invested" do
    investment = build(:investment, quantity: 10.0, average_price: 50.0, current_price: 60.0)
    assert_equal 100.0, investment.profit_loss
  end

  test "profit_loss is negative when losing" do
    investment = build(:investment, quantity: 10.0, average_price: 60.0, current_price: 50.0)
    assert_equal(-100.0, investment.profit_loss)
  end

  test "profit_loss_percent calculates percentage" do
    investment = build(:investment, quantity: 10.0, average_price: 100.0, current_price: 120.0)
    assert_equal 20.0, investment.profit_loss_percent
  end

  test "profit_loss_percent returns 0 when total_invested is zero" do
    investment = build(:investment, quantity: 0, average_price: 0, current_price: 120.0)
    assert_equal 0, investment.profit_loss_percent
  end
end
