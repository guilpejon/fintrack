require "test_helper"

class Expenses::GenerateRecurringJobTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = @user.categories.first
    @template = create(:expense, user: @user, category: @category, recurring: true, date: Date.current)
  end

  test "generates 11 future months from template" do
    assert_difference "Expense.count", 11 do
      Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "generated expenses are linked to template via recurring_source_id" do
    Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Expense.where(recurring_source_id: @template.id)
    assert_equal 11, generated.count
    assert generated.all?(&:recurring?)
  end

  test "does not duplicate already generated months" do
    next_month = Date.current >> 1
    create(:expense, user: @user, category: @category, recurring_source_id: @template.id, date: next_month)

    assert_difference "Expense.count", 10 do
      Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "copies expense attributes from template" do
    Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Expense.where(recurring_source_id: @template.id).first
    assert_equal @template.description, generated.description
    assert_equal @template.amount, generated.amount
    assert_equal @template.expense_type, generated.expense_type
    assert_equal @template.category_id, generated.category_id
    assert_equal @template.payment_method, generated.payment_method
    assert_equal 1, generated.total_installments
    assert_equal 1, generated.installment_number
  end

  test "handles month-end day edge case (day 31 in short month)" do
    template = create(:expense, user: @user, category: @category, recurring: true, date: Date.new(Date.current.year, 1, 31))
    Expenses::GenerateRecurringJob.new.perform(template_id: template.id)
    feb = Expense.where(recurring_source_id: template.id).find { |e| e.date.month == 2 }
    assert_not_nil feb
    assert feb.date.day <= feb.date.end_of_month.day
  end

  test "rescues errors without re-raising" do
    assert_nothing_raised do
      Expenses::GenerateRecurringJob.new.perform(template_id: 0)
    end
  end

  test "when no template_id given processes all recurring templates" do
    other_template = create(:expense, user: @user, category: @category, recurring: true, date: Date.current)

    assert_difference "Expense.count", 22 do
      Expenses::GenerateRecurringJob.new.perform
    end
  end

  test "ignores templates that are generated expenses themselves" do
    generated = create(:expense, user: @user, category: @category, recurring: true, recurring_source_id: @template.id)
    count_before = Expense.count
    Expenses::GenerateRecurringJob.new.perform(template_id: generated.id)
    assert_equal count_before, Expense.count
  end
end
