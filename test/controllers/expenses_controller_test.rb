require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  setup do
    @user = create(:user)
    @category = @user.categories.first
    @expense = create(:expense, user: @user, category: @category)
  end

  test "redirects to sign in when not authenticated" do
    get expenses_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get expenses_path
    assert_response :success
  end

  test "GET index shows fixed expenses in fixed section" do
    fixed = create(:expense, user: @user, category: @category, expense_type: "fixed", description: "Monthly Rent", date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_match fixed.description, response.body
  end

  test "GET index shows variable expenses in variable section" do
    variable = create(:expense, user: @user, category: @category, expense_type: "variable", description: "Groceries Run", date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_match variable.description, response.body
  end

  test "GET index fixed expenses do not bleed into variable section" do
    fixed = create(:expense, user: @user, category: @category, expense_type: "fixed", description: "Internet Bill", date: Date.current)
    variable = create(:expense, user: @user, category: @category, expense_type: "variable", description: "Restaurant Meal", date: Date.current)
    sign_in @user
    get expenses_path
    # Both descriptions must be present somewhere on the page
    assert_match fixed.description, response.body
    assert_match variable.description, response.body
  end

  test "GET index computes fixed and variable totals separately" do
    create(:expense, user: @user, category: @category, expense_type: "fixed", amount: 500.00, date: Date.current)
    create(:expense, user: @user, category: @category, expense_type: "variable", amount: 200.00, date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    # The default @expense from setup is variable with amount 100, so variable total = 300, fixed = 500
    assert_match "500", response.body
    assert_match "300", response.body
  end

  test "GET index only shows current month expenses" do
    last_month = create(:expense, user: @user, category: @category, description: "Old Expense", date: 1.month.ago)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_no_match last_month.description, response.body
  end

  test "GET new returns success" do
    sign_in @user
    get new_expense_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_expense_path(@expense)
    assert_response :success
  end

  test "POST create with valid params creates expense" do
    sign_in @user
    assert_difference "Expense.count", 1 do
      post expenses_path, params: {
        expense: {
          description: "Groceries",
          amount: 150.00,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id
        }
      }
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: { description: nil, amount: nil, date: Date.current, expense_type: "variable", category_id: @category.id }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates expense" do
    sign_in @user
    patch expense_path(@expense), params: {
      expense: { description: "Updated description" }
    }
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.updated"), flash[:notice]
    assert_equal "Updated description", @expense.reload.description
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch expense_path(@expense), params: {
      expense: { description: nil, amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes expense" do
    sign_in @user
    assert_difference "Expense.count", -1 do
      delete expense_path(@expense)
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.destroyed"), flash[:notice]
  end

  test "cannot access other user's expense" do
    other_user = create(:user)
    other_category = other_user.categories.first
    other_expense = create(:expense, user: other_user, category: other_category)

    sign_in @user
    get edit_expense_path(other_expense)
    assert_response :not_found
  end

  test "POST create stores payment_method" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "Transfer",
        amount: 50.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "pix"
      }
    }
    assert_equal "pix", Expense.last.payment_method
  end

  # installment creation
  test "POST create with multiple installments creates correct count" do
    sign_in @user
    assert_difference "Expense.count", 3 do
      post expenses_path, params: {
        expense: {
          description: "New TV",
          amount: 300.00,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id,
          payment_method: "credit_card",
          total_installments: 3,
          installment_number: 1
        }
      }
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.created_installments", count: 3), flash[:notice]
  end

  test "POST create with multiple installments assigns same group_id" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    created = @user.expenses.order(id: :asc).last(3)
    group_ids = created.map(&:installment_group_id).uniq
    assert_equal 1, group_ids.size
    assert_not_nil group_ids.first
  end

  test "POST create with multiple installments splits amount evenly" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    amounts = @user.expenses.order(id: :asc).last(3).map(&:amount).map(&:to_f)
    assert_equal [ 100.0, 100.0, 100.0 ], amounts
  end

  test "POST create with multiple installments advances date by month" do
    sign_in @user
    base = Date.new(2026, 3, 1)
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: base,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    dates = @user.expenses.order(id: :asc).last(3).map(&:date)
    assert_equal [ base, base >> 1, base >> 2 ], dates
  end

  test "POST create with installments and invalid amount re-renders new" do
    sign_in @user
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: {
          description: "Test",
          amount: -1,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id,
          total_installments: 3,
          installment_number: 1
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create recurring expense enqueues GenerateRecurringJob" do
    sign_in @user
    assert_enqueued_with(job: Expenses::GenerateRecurringJob) do
      post expenses_path, params: {
        expense: {
          description: "Monthly Rent",
          amount: 1500.00,
          date: Date.current,
          expense_type: "fixed",
          category_id: @category.id,
          recurring: true,
          recurrence_day: 5
        }
      }
    end
  end

  test "PATCH update_status cycles payment status" do
    sign_in @user
    @expense.update!(payment_status: "pending")
    patch update_status_expense_path(@expense)
    assert_equal "scheduled", @expense.reload.payment_status
  end

  test "PATCH update_status cycles back to pending from paid" do
    sign_in @user
    @expense.update!(payment_status: "paid")
    patch update_status_expense_path(@expense)
    assert_equal "pending", @expense.reload.payment_status
  end

  test "PATCH update on recurring template propagates amount to future replicas" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: 2.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { amount: 200.00 } }

    assert_redirected_to expenses_path
    assert_equal 200.00, template.reload.amount
    assert_equal 200.00, future_replica.reload.amount
    assert_equal 100.00, past_replica.reload.amount  # past replica is not updated
  end

  test "PATCH update on recurring template propagates category to future replicas" do
    other_category = create(:category, user: @user)
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 2.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { category_id: other_category.id } }

    assert_redirected_to expenses_path
    assert_equal other_category.id, template.reload.category_id
    assert_equal other_category.id, future_replica.reload.category_id
    assert_equal @category.id, past_replica.reload.category_id  # past replica is not updated
  end

  test "PATCH update on recurring replica propagates amount to future replicas of same source" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: 3.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 2.months.ago)
    edited_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now)

    sign_in @user
    patch expense_path(edited_replica), params: { expense: { amount: 300.00 } }

    assert_redirected_to expenses_path
    assert_equal 300.00, edited_replica.reload.amount
    assert_equal 300.00, future_replica.reload.amount
    assert_equal 100.00, past_replica.reload.amount  # past replica is not updated
    assert_equal 100.00, template.reload.amount       # template is not updated
  end

  test "PATCH update on recurring template does not propagate unchanged fields" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: 2.months.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now, category_id: @category.id)

    sign_in @user
    patch expense_path(template), params: { expense: { amount: 200.00 } }

    assert_equal @category.id, future_replica.reload.category_id
  end

  test "PATCH update on non-recurring expense does not propagate" do
    non_recurring = create(:expense, user: @user, category: @category, expense_type: "variable", recurring: false, amount: 100.00, date: Date.current)

    sign_in @user
    patch expense_path(non_recurring), params: { expense: { amount: 200.00 } }

    assert_equal 200.00, non_recurring.reload.amount
  end

  test "PATCH update turning off recurring on template destroys future replicas" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 2.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { recurring: "0", expense_type: "fixed" } }

    assert_redirected_to expenses_path
    assert_not Expense.exists?(future_replica.id)
    assert Expense.exists?(past_replica.id)
    assert_not template.reload.recurring?
  end

  test "PATCH update turning off recurring on replica destroys future siblings and turns off template" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 3.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 2.months.ago)
    current_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(current_replica), params: { expense: { recurring: "0", expense_type: "fixed" } }

    assert_redirected_to expenses_path
    assert_not Expense.exists?(future_replica.id)
    assert Expense.exists?(past_replica.id)
    assert_not template.reload.recurring?
  end

  test "PATCH update_status responds via turbo_stream" do
    sign_in @user
    @expense.update!(payment_status: "pending")
    patch update_status_expense_path(@expense), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "DELETE destroy responds via turbo_stream" do
    sign_in @user
    delete expense_path(@expense), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "DELETE destroy with delete_following removes recurring future expenses" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 2.months.ago)
    future1 = create(:expense, user: @user, category: @category, recurring_source_id: template.id, date: 1.month.from_now)
    future2 = create(:expense, user: @user, category: @category, recurring_source_id: template.id, date: 2.months.from_now)
    past = create(:expense, user: @user, category: @category, recurring_source_id: template.id, date: 1.month.ago)

    sign_in @user
    delete expense_path(future1), params: { delete_following: "1" }
    assert_redirected_to expenses_path

    assert_not Expense.exists?(future1.id)
    assert_not Expense.exists?(future2.id)
    assert Expense.exists?(past.id)
  end

  test "DELETE destroy with delete_following for installments removes from that number onward" do
    group_id = SecureRandom.uuid
    inst1 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 1, total_installments: 3)
    inst2 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 2, total_installments: 3)
    inst3 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 3, total_installments: 3)

    sign_in @user
    delete expense_path(inst2), params: { delete_following: "1" }

    assert Expense.exists?(inst1.id)
    assert_not Expense.exists?(inst2.id)
    assert_not Expense.exists?(inst3.id)
    assert_equal 1, inst1.reload.total_installments
  end

  test "DELETE destroy single installment renumbers remaining" do
    group_id = SecureRandom.uuid
    inst1 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 1, total_installments: 3)
    inst2 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 2, total_installments: 3)
    inst3 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 3, total_installments: 3)

    sign_in @user
    delete expense_path(inst1)

    assert_equal 1, inst2.reload.installment_number
    assert_equal 2, inst3.reload.installment_number
    assert_equal 2, inst2.reload.total_installments
  end
end
