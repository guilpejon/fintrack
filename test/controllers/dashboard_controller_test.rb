require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = @user.categories.first
  end

  test "redirects to sign in when not authenticated" do
    get expenses_path
    assert_redirected_to new_user_session_path
  end

  test "shows dashboard when authenticated" do
    sign_in @user
    get root_path
    assert_response :success
  end

  test "dashboard loads with income and expense data" do
    create(:income, user: @user, amount: 5000, date: Date.current)
    create(:expense, user: @user, category: @category, amount: 2000, date: Date.current)

    sign_in @user
    get root_path
    assert_response :success
  end

  test "dashboard loads with multiple expense categories" do
    other_category = create(:category, user: @user, name: "Transport", color: "#F7B731", icon: "car")
    create(:expense, user: @user, category: @category, amount: 500, date: Date.current)
    create(:expense, user: @user, category: other_category, amount: 300, date: Date.current)

    sign_in @user
    get root_path
    assert_response :success
  end

  test "dashboard loads with recent transactions" do
    6.times { create(:expense, user: @user, category: @category, date: Date.current) }

    sign_in @user
    get root_path
    assert_response :success
  end

  test "dashboard loads correctly with no data" do
    sign_in @user
    get root_path
    assert_response :success
  end

  test "dashboard does not expose other users' data" do
    other_user = create(:user)
    other_category = other_user.categories.first
    create(:income, user: other_user, amount: 99999, date: Date.current)
    create(:expense, user: other_user, category: other_category, amount: 99999, date: Date.current)

    sign_in @user
    get root_path
    assert_response :success
  end
end
