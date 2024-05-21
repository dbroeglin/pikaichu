class UsersController < ApplicationController
  def update
    @user = User.find(current_user.id)

    if @user.update(user_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params
      .require(:user)
      .permit(
        :firstname,
        :lastname,
        :email,
        :locale
      )
  end
end
