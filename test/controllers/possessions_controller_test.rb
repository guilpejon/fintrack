require "test_helper"

class PossessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @possession = create(:possession, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get possessions_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get possessions_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_possession_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_possession_path(@possession)
    assert_response :success
  end

  test "POST create with valid params creates possession" do
    sign_in @user
    assert_difference "Possession.count", 1 do
      post possessions_path, params: {
        possession: {
          name: "MacBook Pro",
          possession_type: "electronics",
          purchase_price: 15000.0,
          current_value: 12000.0,
          purchase_date: "2024-01-15",
          currency: "BRL",
          color: "#6C63FF"
        }
      }
    end
    assert_redirected_to possessions_path
    assert_equal I18n.t("controllers.possessions.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Possession.count" do
      post possessions_path, params: {
        possession: { name: nil, possession_type: "invalid" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates possession" do
    sign_in @user
    patch possession_path(@possession), params: {
      possession: { name: "Updated Name" }
    }
    assert_redirected_to possessions_path
    assert_equal I18n.t("controllers.possessions.updated"), flash[:notice]
    assert_equal "Updated Name", @possession.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch possession_path(@possession), params: {
      possession: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes possession" do
    sign_in @user
    assert_difference "Possession.count", -1 do
      delete possession_path(@possession)
    end
    assert_redirected_to possessions_path
    assert_equal I18n.t("controllers.possessions.destroyed"), flash[:notice]
  end

  test "cannot access other user's possession" do
    other_user = create(:user)
    other_possession = create(:possession, user: other_user)

    sign_in @user
    get edit_possession_path(other_possession)
    assert_response :not_found
  end

  test "cannot update other user's possession" do
    other_user = create(:user)
    other_possession = create(:possession, user: other_user)

    sign_in @user
    patch possession_path(other_possession), params: {
      possession: { name: "Hacked" }
    }
    assert_response :not_found
  end

  test "cannot delete other user's possession" do
    other_user = create(:user)
    other_possession = create(:possession, user: other_user)

    sign_in @user
    assert_no_difference "Possession.count" do
      delete possession_path(other_possession)
    end
    assert_response :not_found
  end

  test "index computes correct totals" do
    sign_in @user
    @possession.update!(purchase_price: 10000, current_value: 8000)
    create(:possession, user: @user, purchase_price: 5000, current_value: 6000)

    get possessions_path
    assert_response :success
  end
end
