require "test_helper"

class User::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "redirects to sign in when not authenticated" do
    get edit_user_settings_path
    assert_redirected_to new_user_session_path
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_user_settings_path
    assert_response :success
  end

  test "PATCH update profile with valid params updates user" do
    sign_in @user
    patch user_settings_path, params: {
      user: { name: "New Name", currency: "USD", locale: "en" }
    }
    assert_redirected_to edit_user_settings_path
    assert_equal "New Name", @user.reload.name
    assert_equal "USD", @user.reload.currency
  end

  test "PATCH update profile with invalid params re-renders edit" do
    sign_in @user
    patch user_settings_path, params: {
      user: { name: "", email: "not-an-email" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update password with correct current password updates password" do
    sign_in @user
    patch user_settings_path, params: {
      section: "password",
      user: {
        current_password: "password123",
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    assert_redirected_to edit_user_settings_path
    assert @user.reload.valid_password?("newpassword456")
  end

  test "PATCH update password with wrong current password re-renders edit" do
    sign_in @user
    patch user_settings_path, params: {
      section: "password",
      user: {
        current_password: "wrongpassword",
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update password with mismatched confirmation re-renders edit" do
    sign_in @user
    patch user_settings_path, params: {
      section: "password",
      user: {
        current_password: "password123",
        password: "newpassword456",
        password_confirmation: "different"
      }
    }
    assert_response :unprocessable_entity
  end
end
