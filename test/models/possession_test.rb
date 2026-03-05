require "test_helper"

class PossessionTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    possession = build(:possession)
    assert possession.valid?
  end

  test "requires name" do
    possession = build(:possession, name: nil)
    assert_not possession.valid?
    assert possession.errors[:name].any?
  end

  test "validates possession_type inclusion" do
    possession = build(:possession, possession_type: "invalid")
    assert_not possession.valid?
  end

  test "accepts all valid possession types" do
    %w[vehicle electronics real_estate furniture jewelry other].each do |type|
      possession = build(:possession, possession_type: type)
      assert possession.valid?, "Expected #{type} to be valid"
    end
  end

  test "purchase_price must be >= 0" do
    possession = build(:possession, purchase_price: -1)
    assert_not possession.valid?
    assert possession.errors[:purchase_price].any?
  end

  test "current_value must be >= 0" do
    possession = build(:possession, current_value: -1)
    assert_not possession.valid?
    assert possession.errors[:current_value].any?
  end

  test "purchase_price and current_value can be nil" do
    possession = build(:possession, purchase_price: nil, current_value: nil)
    assert possession.valid?
  end

  test "value_change returns difference between current and purchase price" do
    possession = build(:possession, purchase_price: 10000, current_value: 8000)
    assert_equal(-2000, possession.value_change)
  end

  test "value_change returns positive when current > purchase" do
    possession = build(:possession, purchase_price: 5000, current_value: 7000)
    assert_equal 2000, possession.value_change
  end

  test "value_change returns nil when purchase_price is nil" do
    possession = build(:possession, purchase_price: nil, current_value: 8000)
    assert_nil possession.value_change
  end

  test "value_change returns nil when current_value is nil" do
    possession = build(:possession, purchase_price: 10000, current_value: nil)
    assert_nil possession.value_change
  end

  test "value_change_percent returns correct percentage" do
    possession = build(:possession, purchase_price: 10000, current_value: 8000)
    assert_equal(-20.0, possession.value_change_percent)
  end

  test "value_change_percent returns positive percentage when appreciated" do
    possession = build(:possession, purchase_price: 10000, current_value: 12000)
    assert_equal 20.0, possession.value_change_percent
  end

  test "value_change_percent returns nil when purchase_price is zero" do
    possession = build(:possession, purchase_price: 0, current_value: 5000)
    assert_nil possession.value_change_percent
  end

  test "value_change_percent returns nil when purchase_price is nil" do
    possession = build(:possession, purchase_price: nil, current_value: 5000)
    assert_nil possession.value_change_percent
  end

  test "value_change_percent returns nil when current_value is nil" do
    possession = build(:possession, purchase_price: 10000, current_value: nil)
    assert_nil possession.value_change_percent
  end

  test "COLORS references BankAccount::COLORS" do
    assert_equal BankAccount::COLORS, Possession::COLORS
  end
end
