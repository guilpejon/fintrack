require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    category = build(:category)
    assert category.valid?
  end

  test "requires name" do
    category = build(:category, name: nil)
    assert_not category.valid?
    assert category.errors[:name].any?
  end

  test "requires color" do
    category = build(:category, color: nil)
    assert_not category.valid?
    assert category.errors[:color].any?
  end

  test "requires icon" do
    category = build(:category, icon: nil)
    assert_not category.valid?
    assert category.errors[:icon].any?
  end

  test "belongs to a user" do
    category = build(:category)
    assert_not_nil category.user
  end

  test "has many expenses" do
    category = create(:category)
    expense = create(:expense, user: category.user, category: category)
    assert_includes category.expenses, expense
  end
end
