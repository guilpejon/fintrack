require "test_helper"

class IncomesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  setup do
    @user = create(:user)
    @income = create(:income, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get incomes_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get incomes_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_income_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_income_path(@income)
    assert_response :success
  end

  test "POST create with valid params creates income" do
    sign_in @user
    assert_difference "Income.count", 1 do
      post incomes_path, params: {
        income: {
          description: "Monthly salary",
          amount: 5000.00,
          date: Date.current,
          income_type: "salary"
        }
      }
    end
    assert_redirected_to incomes_path
    assert_equal I18n.t("controllers.incomes.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Income.count" do
      post incomes_path, params: {
        income: { description: nil, amount: nil, date: Date.current, income_type: "salary" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates income" do
    sign_in @user
    patch income_path(@income), params: {
      income: { description: "Updated salary" }
    }
    assert_redirected_to incomes_path
    assert_equal I18n.t("controllers.incomes.updated"), flash[:notice]
    assert_equal "Updated salary", @income.reload.description
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch income_path(@income), params: {
      income: { description: nil, amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes income" do
    sign_in @user
    assert_difference "Income.count", -1 do
      delete income_path(@income)
    end
    assert_redirected_to incomes_path
    assert_equal I18n.t("controllers.incomes.destroyed"), flash[:notice]
  end

  test "cannot access other user's income" do
    other_user = create(:user)
    other_income = create(:income, user: other_user)

    sign_in @user
    get edit_income_path(other_income)
    assert_response :not_found
  end

  test "POST create recurring income enqueues GenerateRecurringJob" do
    sign_in @user
    assert_enqueued_with(job: Incomes::GenerateRecurringJob) do
      post incomes_path, params: {
        income: {
          description: "Monthly Salary",
          amount: 5000.00,
          date: Date.current,
          income_type: "salary",
          recurring: true,
          recurrence_day: 5
        }
      }
    end
  end

  test "DELETE destroy with delete_following removes recurring future incomes" do
    template = create(:income, user: @user, recurring: true, date: 2.months.ago)
    future1 = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.from_now)
    future2 = create(:income, user: @user, recurring_source_id: template.id, date: 2.months.from_now)
    past = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.ago)

    sign_in @user
    delete income_path(future1), params: { delete_following: "1" }
    assert_redirected_to incomes_path

    assert_not Income.exists?(future1.id)
    assert_not Income.exists?(future2.id)
    assert Income.exists?(past.id)
  end

  test "cannot update other user's income" do
    other_user = create(:user)
    other_income = create(:income, user: other_user)

    sign_in @user
    patch income_path(other_income), params: { income: { description: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's income" do
    other_user = create(:user)
    other_income = create(:income, user: other_user)

    sign_in @user
    assert_no_difference "Income.count" do
      delete income_path(other_income)
    end
    assert_response :not_found
  end

  test "PATCH update turning off recurring on template destroys future replicas" do
    template = create(:income, user: @user, recurring: true, date: 2.months.ago)
    past_replica = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.ago)
    future_replica = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch income_path(template), params: { income: { recurring: "0" } }

    assert_redirected_to incomes_path
    assert_not Income.exists?(future_replica.id)
    assert Income.exists?(past_replica.id)
    assert_not template.reload.recurring?
  end

  test "PATCH update turning off recurring on replica destroys future siblings and turns off template" do
    template = create(:income, user: @user, recurring: true, date: 3.months.ago)
    past_replica = create(:income, user: @user, recurring_source_id: template.id, date: 2.months.ago)
    current_replica = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.ago, recurring: true)
    future_replica = create(:income, user: @user, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch income_path(current_replica), params: { income: { recurring: "0" } }

    assert_redirected_to incomes_path
    assert_not Income.exists?(future_replica.id)
    assert Income.exists?(past_replica.id)
    assert_not template.reload.recurring?
  end

  test "DELETE destroy turbo_stream removes income element" do
    sign_in @user
    delete income_path(@income), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end
end
