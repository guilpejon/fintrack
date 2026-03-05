require "test_helper"

class Incomes::GenerateRecurringJobTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @template = create(:income, user: @user, recurring: true, date: Date.current)
  end

  test "generates 11 future months from template" do
    # i=0 is the template's own month and is skipped
    assert_difference "Income.count", 11 do
      Incomes::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "generated incomes are linked to template via recurring_source_id" do
    Incomes::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Income.where(recurring_source_id: @template.id)
    assert_equal 11, generated.count
    assert generated.all?(&:recurring?)
  end

  test "does not duplicate already generated months" do
    next_month = Date.current >> 1
    create(:income, user: @user, recurring_source_id: @template.id, date: next_month)

    assert_difference "Income.count", 10 do
      Incomes::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "copies income attributes from template" do
    Incomes::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Income.where(recurring_source_id: @template.id).first
    assert_equal @template.description, generated.description
    assert_equal @template.amount, generated.amount
    assert_equal @template.income_type, generated.income_type
  end

  test "handles month-end day edge case (day 31 in short month)" do
    template = create(:income, user: @user, recurring: true, date: Date.new(Date.current.year, 1, 31))
    Incomes::GenerateRecurringJob.new.perform(template_id: template.id)
    feb = Income.where(recurring_source_id: template.id).find { |i| i.date.month == 2 }
    assert_not_nil feb
    assert feb.date.day <= feb.date.end_of_month.day
  end

  test "rescues errors without re-raising" do
    assert_nothing_raised do
      Incomes::GenerateRecurringJob.new.perform(template_id: 0)
    end
  end

  test "when no template_id given processes all recurring templates" do
    other_template = create(:income, user: @user, recurring: true, date: Date.current)

    assert_difference "Income.count", 22 do
      Incomes::GenerateRecurringJob.new.perform
    end
  end

  test "ignores templates that are generated incomes themselves" do
    generated = create(:income, user: @user, recurring: true, recurring_source_id: @template.id)
    count_before = Income.count
    Incomes::GenerateRecurringJob.new.perform(template_id: generated.id)
    assert_equal count_before, Income.count
  end
end
