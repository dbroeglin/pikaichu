class StaffsController < ApplicationController

  def edit
    @taikai = Taikai.find(params[:taikai_id])
    @staff = @taikai.staffs.find(params[:id])
  end

  def update
    @taikai = Taikai.find(params[:taikai_id])
    @staff = @taikai.staffs.find(params[:id])

    if @staff.update(staff_params)
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit
    end
  end

  def destroy
    @taikai = Taikai.find(params[:taikai_id])
    @staff = @taikai.staffs.find(params[:id])

    @staff.destroy
    redirect_to controller: 'taikais', action: 'edit', id: @taikai
  end

  private

  def staff_params
    params
      .require(:staff)
      .permit(
        :taikai_id,
        :user_id,
        :role_id,
        :firstname,
        :lastname,
      )
  end
end
