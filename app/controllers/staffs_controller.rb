class StaffsController < ApplicationController
  layout 'taikai'

  before_action :set_taikai

  def new
    @staff = @taikai.staffs.build
  end

  def create
    @staff = @taikai.staffs.build(staff_params)

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

    if @staff.update(staff_params)
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @staff = @taikai.staffs.find(params[:id])

    if !@staff.destroy
      flash[:alert] = @staff.errors.full_messages.join(', ')
    end
    redirect_to controller: 'taikais', action: 'edit', id: @taikai, status: :see_other
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
        :participating_dojo_id,
      )
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end
end
