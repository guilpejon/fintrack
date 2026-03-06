require "test_helper"

class IncomeTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    income = build(:income)
    assert income.valid?
  end

  test "requires description" do
    income = build(:income, description: nil)
    assert_not income.valid?
    assert income.errors[:description].any?
  end

  test "requires amount" do
    income = build(:income, amount: nil)
    assert_not income.valid?
    assert income.errors[:amount].any?
  end

  test "requires amount greater than zero" do
    income = build(:income, amount: 0)
    assert_not income.valid?
    income2 = build(:income, amount: -100)
    assert_not income2.valid?
  end

  test "requires date" do
    income = build(:income, date: nil)
    assert_not income.valid?
    assert income.errors[:date].any?
  end

  test "requires valid income_type" do
    income = build(:income, income_type: "invalid")
    assert_not income.valid?
  end

  test "accepts all valid income types" do
    %w[salary freelance dividend other].each do |type|
      income = build(:income, income_type: type)
      assert income.valid?, "Expected #{type} to be valid"
    end
  end

  test "validates recurrence_day is between 1 and 28" do
    income = build(:income, recurrence_day: 0)
    assert_not income.valid?

    income2 = build(:income, recurrence_day: 29)
    assert_not income2.valid?
  end

  test "accepts nil recurrence_day" do
    income = build(:income, recurrence_day: nil)
    assert income.valid?
  end

  test "for_month scope filters by month" do
    user = create(:user)
    this_month = create(:income, user: user, date: Date.current)
    last_month = create(:income, user: user, date: 1.month.ago)

    results = Income.for_month(Date.current)
    assert_includes results, this_month
    assert_not_includes results, last_month
  end

  test "ordered scope orders by date descending" do
    user = create(:user)
    old = create(:income, user: user, date: 3.days.ago)
    recent = create(:income, user: user, date: Date.current)

    ordered = Income.ordered.to_a
    assert_equal recent, ordered.first
    assert_equal old, ordered.last
  end

  test "recurring scope returns only recurring incomes" do
    user = create(:user)
    recurring = create(:income, user: user, recurring: true, recurrence_day: 5)
    one_time = create(:income, user: user, recurring: false)

    assert_includes Income.where(recurring: true), recurring
    assert_not_includes Income.where(recurring: true), one_time
  end
end
