require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = @user.categories.first
  end

  test "redirects to sign in when not authenticated" do
    get categories_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get categories_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_category_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_category_path(@category)
    assert_response :success
  end

  test "POST create with valid params creates category" do
    sign_in @user
    assert_difference "Category.count", 1 do
      post categories_path, params: {
        category: { name: "Pets", color: "#FF5733", icon: "paw-print" }
      }
    end
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Category.count" do
      post categories_path, params: {
        category: { name: nil, color: nil, icon: nil }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates category" do
    sign_in @user
    patch category_path(@category), params: {
      category: { name: "Updated Name" }
    }
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.updated"), flash[:notice]
    assert_equal "Updated Name", @category.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch category_path(@category), params: {
      category: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes category" do
    sign_in @user
    assert_difference "Category.count", -1 do
      delete category_path(@category)
    end
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.destroyed"), flash[:notice]
  end

  test "cannot access other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.first

    sign_in @user
    get edit_category_path(other_category)
    assert_response :not_found
  end

  test "cannot update other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.first

    sign_in @user
    patch category_path(other_category), params: { category: { name: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.first

    sign_in @user
    delete category_path(other_category)
    assert_response :not_found
  end
end
