class StaffsController < ApplicationController
  before_action :set_taikai

  def new
    @staff = @taikai.staffs.build
  end

  def create
    @staff = @taikai.staffs.build(staff_params)
    complete_staff

    if @staff.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @staff = @taikai.staffs.find(params[:id])
  end

  def update
    @staff = @taikai.staffs.find(params[:id])
    @staff.assign_attributes(staff_params)
    complete_staff

    if @staff.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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

  def complete_staff
    if @staff.user
      @staff.firstname = @staff.user.firstname
      @staff.lastname = @staff.user.lastname
    end
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end
end
