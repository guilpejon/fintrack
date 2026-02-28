require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @investment = create(:investment, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get investments_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get investments_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_investment_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_investment_path(@investment)
    assert_response :success
  end

  test "POST create with valid params creates investment" do
    sign_in @user
    assert_difference "Investment.count", 1 do
      post investments_path, params: {
        investment: {
          name: "Apple Inc",
          ticker: "AAPL",
          investment_type: "stock",
          quantity: 5.0,
          average_price: 150.00,
          current_price: 175.00,
          currency: "USD"
        }
      }
    end
    assert_redirected_to investments_path
    assert_equal "Investment added.", flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Investment.count" do
      post investments_path, params: {
        investment: { name: nil, investment_type: "invalid" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates investment" do
    sign_in @user
    patch investment_path(@investment), params: {
      investment: { name: "Updated Name" }
    }
    assert_redirected_to investments_path
    assert_equal "Investment updated.", flash[:notice]
    assert_equal "Updated Name", @investment.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch investment_path(@investment), params: {
      investment: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes investment" do
    sign_in @user
    assert_difference "Investment.count", -1 do
      delete investment_path(@investment)
    end
    assert_redirected_to investments_path
    assert_equal "Investment removed.", flash[:notice]
  end

  test "cannot access other user's investment" do
    other_user = create(:user)
    other_investment = create(:investment, user: other_user)

    sign_in @user
    get edit_investment_path(other_investment)
    assert_response :not_found
  end
end
