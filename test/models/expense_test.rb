require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    expense = build(:expense)
    assert expense.valid?
  end

  test "requires description" do
    expense = build(:expense, description: nil)
    assert_not expense.valid?
    assert_includes expense.errors[:description], "can't be blank"
  end

  test "requires amount" do
    expense = build(:expense, amount: nil)
    assert_not expense.valid?
    assert_includes expense.errors[:amount], "can't be blank"
  end

  test "requires amount greater than zero" do
    expense = build(:expense, amount: 0)
    assert_not expense.valid?
    expense2 = build(:expense, amount: -5)
    assert_not expense2.valid?
  end

  test "requires date" do
    expense = build(:expense, date: nil)
    assert_not expense.valid?
    assert_includes expense.errors[:date], "can't be blank"
  end

  test "requires valid expense_type" do
    expense = build(:expense, expense_type: "invalid")
    assert_not expense.valid?
  end

  test "accepts fixed expense_type" do
    expense = build(:expense, expense_type: "fixed")
    assert expense.valid?
  end

  test "accepts variable expense_type" do
    expense = build(:expense, expense_type: "variable")
    assert expense.valid?
  end

  test "validates recurrence_day is between 1 and 28" do
    expense = build(:expense, recurrence_day: 0)
    assert_not expense.valid?

    expense2 = build(:expense, recurrence_day: 29)
    assert_not expense2.valid?
  end

  test "accepts nil recurrence_day" do
    expense = build(:expense, recurrence_day: nil)
    assert expense.valid?
  end

  test "for_month scope filters by month" do
    user = create(:user)
    category = user.categories.first
    this_month = create(:expense, user: user, category: category, date: Date.current)
    last_month = create(:expense, user: user, category: category, date: 1.month.ago)

    results = Expense.for_month(Date.current)
    assert_includes results, this_month
    assert_not_includes results, last_month
  end

  test "ordered scope orders by date descending" do
    user = create(:user)
    category = user.categories.first
    old = create(:expense, user: user, category: category, date: 3.days.ago)
    recent = create(:expense, user: user, category: category, date: Date.current)

    ordered = Expense.ordered.to_a
    assert_equal recent, ordered.first
    assert_equal old, ordered.last
  end

  test "fixed scope returns only fixed expenses" do
    user = create(:user)
    category = user.categories.first
    fixed = create(:expense, user: user, category: category, expense_type: "fixed")
    variable = create(:expense, user: user, category: category, expense_type: "variable")

    assert_includes Expense.fixed, fixed
    assert_not_includes Expense.fixed, variable
  end

  test "variable scope returns only variable expenses" do
    user = create(:user)
    category = user.categories.first
    fixed = create(:expense, user: user, category: category, expense_type: "fixed")
    variable = create(:expense, user: user, category: category, expense_type: "variable")

    assert_includes Expense.variable, variable
    assert_not_includes Expense.variable, fixed
  end

  test "recurring scope returns only recurring expenses" do
    user = create(:user)
    category = user.categories.first
    recurring = create(:expense, user: user, category: category, recurring: true, recurrence_day: 5)
    one_time = create(:expense, user: user, category: category, recurring: false)

    assert_includes Expense.recurring, recurring
    assert_not_includes Expense.recurring, one_time
  end
end
