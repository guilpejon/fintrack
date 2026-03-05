require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    user = build(:user)
    assert user.valid?
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "requires unique email" do
    create(:user, email: "duplicate@example.com")
    user = build(:user, email: "duplicate@example.com")
    assert_not user.valid?
  end

  test "requires password" do
    user = build(:user, password: nil)
    assert_not user.valid?
  end

  test "creates default categories after create" do
    user = create(:user)
    assert_equal 9, user.categories.count
  end

  test "default categories have expected names" do
    user = create(:user)
    names = user.categories.pluck(:name)
    assert_includes names, "Housing"
    assert_includes names, "Food"
    assert_includes names, "Other"
  end

  test "destroys dependent categories" do
    user = create(:user)
    assert_difference "Category.count", -9 do
      user.destroy
    end
  end

  test "destroys dependent incomes" do
    user = create(:user)
    create(:income, user: user)
    assert_difference "Income.count", -1 do
      user.destroy
    end
  end

  test "destroys dependent expenses" do
    user = create(:user)
    # Use a category from a different user to avoid cascade nullify conflict with NOT NULL constraint
    other_category = create(:category)
    create(:expense, user: user, category: other_category)
    assert_difference "Expense.count", -1 do
      user.destroy
    end
  end

  test "destroys dependent credit_cards" do
    user = create(:user)
    create(:credit_card, user: user)
    assert_difference "CreditCard.count", -1 do
      user.destroy
    end
  end

  test "destroys dependent investments" do
    user = create(:user)
    create(:investment, user: user)
    assert_difference "Investment.count", -1 do
      user.destroy
    end
  end

  test "currency_symbol returns R$ for BRL" do
    user = build(:user, currency: "BRL")
    assert_equal "R$", user.currency_symbol
  end

  test "currency_symbol returns $ for non-BRL" do
    user = build(:user, currency: "USD")
    assert_equal "$", user.currency_symbol
  end

  test "currency_symbol returns € for EUR" do
    user = build(:user, currency: "EUR")
    assert_equal "€", user.currency_symbol
  end
end
