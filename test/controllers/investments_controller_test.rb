require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
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
    assert_equal I18n.t("controllers.investments.created"), flash[:notice]
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
    assert_equal I18n.t("controllers.investments.updated"), flash[:notice]
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
    assert_equal I18n.t("controllers.investments.destroyed"), flash[:notice]
  end

  test "cannot access other user's investment" do
    other_user = create(:user)
    other_investment = create(:investment, user: other_user)

    sign_in @user
    get edit_investment_path(other_investment)
    assert_response :not_found
  end

  test "cannot update other user's investment" do
    other_user = create(:user)
    other_investment = create(:investment, user: other_user)

    sign_in @user
    patch investment_path(other_investment), params: { investment: { name: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's investment" do
    other_user = create(:user)
    other_investment = create(:investment, user: other_user)

    sign_in @user
    assert_no_difference "Investment.count" do
      delete investment_path(other_investment)
    end
    assert_response :not_found
  end

  test "POST create with ticker enqueues FetchPriceJob" do
    sign_in @user
    assert_enqueued_with(job: Investments::FetchPriceJob, args: [ "AAPL", "stock" ]) do
      post investments_path, params: {
        investment: {
          name: "Apple",
          ticker: "AAPL",
          investment_type: "stock",
          quantity: 1.0,
          average_price: 150.0,
          current_price: 150.0,
          currency: "USD"
        }
      }
    end
  end

  test "POST refresh_price for stale investment enqueues FetchPriceJob" do
    @investment.update!(last_price_update_at: 2.hours.ago)

    sign_in @user
    assert_enqueued_with(job: Investments::FetchPriceJob) do
      post refresh_price_investment_path(@investment)
    end
    assert_redirected_to investments_path
  end

  test "POST refresh_price for fresh investment does not enqueue job" do
    @investment.update!(last_price_update_at: 5.minutes.ago)

    sign_in @user
    assert_no_enqueued_jobs do
      post refresh_price_investment_path(@investment)
    end
    assert_redirected_to investments_path
  end

  test "POST refresh_all_prices enqueues jobs for stale investments" do
    @investment.update!(last_price_update_at: nil)

    sign_in @user
    assert_enqueued_jobs 1, only: Investments::FetchPriceJob do
      post refresh_all_prices_investments_path
    end
    assert_redirected_to investments_path
  end

  test "POST refresh_all_prices with all fresh investments does not enqueue" do
    @investment.update!(last_price_update_at: 5.minutes.ago)

    sign_in @user
    assert_no_enqueued_jobs do
      post refresh_all_prices_investments_path
    end
    assert_redirected_to investments_path
  end
end
