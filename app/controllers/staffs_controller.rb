class StaffsController < ApplicationController
  layout "taikai"

  before_action :set_taikai
  before_action :authorize_taikai
  after_action :verify_authorized

  def new
    @staff = @taikai.staffs.build
  end

  def edit
    @staff = @taikai.staffs.find(params[:id])
  end

  def create
    @staff = @taikai.staffs.build(staff_params)

    if @staff.save
      redirect_to controller: "taikais", action: "edit", id: @taikai
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @staff = @taikai.staffs.find(params[:id])

    if @staff.update(staff_params)
      redirect_to controller: "taikais", action: "edit", id: @taikai
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @staff = @taikai.staffs.find(params[:id])

    flash[:alert] = @staff.errors.full_messages.join(", ") unless @staff.destroy
    redirect_to controller: "taikais", action: "edit", id: @taikai, status: :see_other
  end

  private

  def staff_params
    params
      .require(:staff)
      .permit(
        :user_id,
        :role_id,
        :firstname,
        :lastname,
        :participating_dojo_id,
      )
      .tap do |permitted|
        next if permitted[:participating_dojo_id].blank?

        permitted[:participating_dojo_id] =
          @taikai.participating_dojos.find(permitted[:participating_dojo_id]).id
      end
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def authorize_taikai
    authorize @taikai, :update?
  end
end
