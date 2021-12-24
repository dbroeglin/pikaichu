class StaffsController < ApplicationController
  before_action :set_taikai


  def edit
    @staff = @taikai.staffs.find(params[:id])
  end

  def update
    @staff = @taikai.staffs.find(params[:id])

    if @staff.update(staff_params)
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit
    end
  end

  def new
    @staff = @taikai.staffs.build
  end

  def create
    @staff = @taikai.staffs.build(staff_params)

    if @staff.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :new
    end
  end


  def destroy
    @staff = @taikai.staffs.find(params[:id])

    @staff.destroy
    redirect_to controller: 'taikais', action: 'edit', id: @taikai
  end

  private

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

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
