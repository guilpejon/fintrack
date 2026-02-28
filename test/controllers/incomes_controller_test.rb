require "test_helper"

class IncomesControllerTest < ActionDispatch::IntegrationTest
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
    assert_equal "Income added.", flash[:notice]
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
    assert_equal "Income updated.", flash[:notice]
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
    assert_equal "Income deleted.", flash[:notice]
  end

  test "cannot access other user's income" do
    other_user = create(:user)
    other_income = create(:income, user: other_user)

    sign_in @user
    get edit_income_path(other_income)
    assert_response :not_found
  end
end
