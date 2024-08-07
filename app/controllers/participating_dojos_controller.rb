class ParticipatingDojosController < ApplicationController
  layout 'taikai'

  before_action :set_taikai

  def new
    @participating_dojo = @taikai.participating_dojos.build
  end

  def edit
    @participating_dojo = authorize @taikai
                          .participating_dojos
                          .includes({ participants: :kyudojin }, :teams)
                          .find(params[:id])
  end

  def create
    @participating_dojo = @taikai.participating_dojos.build(participating_dojo_params)
    @dojo = Dojo.find(params[:participating_dojo][:dojo_id])

    @participating_dojo.display_name = @dojo.shortname if @participating_dojo.display_name.blank?
    if @participating_dojo.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @participating_dojo = authorize @taikai.participating_dojos.find(params[:id])
    @dojo = Dojo.find(params[:participating_dojo][:dojo_id])

    @participating_dojo.assign_attributes(participating_dojo_params)
    @participating_dojo.display_name = @dojo.shortname if @participating_dojo.display_name.blank?

    if @participating_dojo.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @participating_dojo = @taikai.participating_dojos.find(params[:id])

    if @participating_dojo.staffs.any?
      flash[:alert] =
        "Unable to remove participating dojo '#{@participating_dojo.display_name}' because " \
        "it is associated to staff members #{@participating_dojo.staffs.map(&:display_name).join ', '}"
    elsif !@participating_dojo.destroy
      flash[:alert] = "Unable to remove participating dojo #{@participating_dojo.display_name}"
    end
    redirect_to controller: 'taikais', action: 'edit', id: @taikai, status: :see_other
  end

  def draw
    @participating_dojo = authorize @taikai.participating_dojos.find(params[:id])

    if @participating_dojo.draw
      flash[:notice] = t :draw_ok
    else
      flash[:alert] = @participating_dojo.errors.full_messages.join("; ")
    end

    redirect_to controller: :taikais, action: :show, id: @taikai
  end

  private

  def participating_dojo_params
    params.require(:participating_dojo).permit(
      :taikai_id,
      :dojo_id,
      :display_name
    )
  end

  def dojo_params
    params.require(:dojo).permit(:name)
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end
end
