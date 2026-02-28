class User::SettingsController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if params[:section] == "password"
      update_password
    else
      update_profile
    end
  end

  private

  def update_profile
    if @user.update(profile_params)
      redirect_to edit_user_settings_path, notice: "Settings saved successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to edit_user_settings_path, notice: "Password updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def profile_params
    params.require(:user).permit(:name, :email, :currency)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
