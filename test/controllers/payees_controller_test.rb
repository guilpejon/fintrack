require "test_helper"

class PayeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @payee = create(:payee, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get payees_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get payees_path
    assert_response :success
  end

  test "GET index JSON returns matching payees" do
    sign_in @user
    create(:payee, user: @user, name: "Supermercado Extra")
    create(:payee, user: @user, name: "Academia")

    get payees_path(q: "super"), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "Supermercado Extra", body.first["name"]
  end

  test "GET index JSON does not return other users' payees" do
    other = create(:user)
    create(:payee, user: other, name: "Secret Store")

    sign_in @user
    get payees_path(q: "secret"), as: :json
    assert_equal [], JSON.parse(response.body)
  end

  test "GET new returns success" do
    sign_in @user
    get new_payee_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_payee_path(@payee)
    assert_response :success
  end

  test "POST create with valid params creates payee" do
    sign_in @user
    assert_difference "Payee.count", 1 do
      post payees_path, params: { payee: { name: "Padaria Silva" } }
    end
    assert_redirected_to payees_path
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Payee.count" do
      post payees_path, params: { payee: { name: nil } }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates payee" do
    sign_in @user
    patch payee_path(@payee), params: { payee: { name: "Updated Name" } }
    assert_redirected_to payees_path
    assert_equal "Updated Name", @payee.reload.name
  end

  test "PATCH update with valid params responds to JSON" do
    sign_in @user
    patch payee_path(@payee), params: { payee: { name: "JSON Name" } }, as: :json
    assert_response :success
    assert_equal "JSON Name", JSON.parse(response.body)["name"]
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch payee_path(@payee), params: { payee: { name: nil } }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes payee" do
    sign_in @user
    assert_difference "Payee.count", -1 do
      delete payee_path(@payee)
    end
    assert_redirected_to payees_path
  end

  test "cannot access other user's payee" do
    other = create(:user)
    other_payee = create(:payee, user: other)

    sign_in @user
    get edit_payee_path(other_payee)
    assert_response :not_found
  end

  test "cannot update other user's payee" do
    other = create(:user)
    other_payee = create(:payee, user: other)

    sign_in @user
    patch payee_path(other_payee), params: { payee: { name: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's payee" do
    other = create(:user)
    other_payee = create(:payee, user: other)

    sign_in @user
    assert_no_difference "Payee.count" do
      delete payee_path(other_payee)
    end
    assert_response :not_found
  end
end
