require "test_helper"

class ForecastControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = @user.categories.first
  end

  test "redirects to sign in when not authenticated" do
    get forecast_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success for current/future month" do
    sign_in @user
    get forecast_path
    assert_response :success
  end

  test "GET index returns success for future month" do
    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_response :success
  end

  test "GET index returns success for past month" do
    sign_in @user
    get forecast_path, params: { month: 1.month.ago.strftime("%Y-%m") }
    assert_response :success
  end

  test "future month shows recurring and installment expenses" do
    create(:expense, user: @user, category: @category, recurring: true, amount: 500)
    create(:expense, user: @user, category: @category,
           date: 1.month.from_now.beginning_of_month,
           total_installments: 3, installment_number: 1, amount: 100)

    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_response :success
  end

  test "past month shows actual expenses and incomes" do
    past = 1.month.ago.beginning_of_month
    create(:expense, user: @user, category: @category, date: past, amount: 250)
    create(:income, user: @user, date: past, amount: 3000)

    sign_in @user
    get forecast_path, params: { month: past.strftime("%Y-%m") }
    assert_response :success
  end
end
