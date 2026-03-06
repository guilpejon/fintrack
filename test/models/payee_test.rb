require "test_helper"

class PayeeTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    payee = build(:payee)
    assert payee.valid?
  end

  test "requires name" do
    payee = build(:payee, name: nil)
    assert_not payee.valid?
    assert payee.errors[:name].any?
  end

  test "requires name to be non-blank" do
    payee = build(:payee, name: "")
    assert_not payee.valid?
  end

  test "belongs to a user" do
    payee = build(:payee)
    assert_not_nil payee.user
  end

  test "nullifies expenses on destroy" do
    user = create(:user)
    category = user.categories.first
    payee = create(:payee, user: user)
    expense = create(:expense, user: user, category: category, payee: payee)

    payee.destroy

    assert_nil expense.reload.payee_id
    assert Expense.exists?(expense.id)
  end

  test "user cannot access other user payees" do
    user1 = create(:user)
    user2 = create(:user)
    payee = create(:payee, user: user1)

    assert_not user2.payees.exists?(payee.id)
  end
end
