class ParticipatingDojosController < ApplicationController
  before_action :set_taikai

  def new
    @participating_dojo = @taikai.participating_dojos.build
  end

  def create
    @participating_dojo = @taikai.participating_dojos.build(participating_dojo_params)

    if @participating_dojo.display_name.blank?
      @participating_dojo.display_name = dojo_params[:name]
    end
    if @participating_dojo.save
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :new
    end
  end

  def edit
    @participating_dojo = @taikai.participating_dojos.find(params[:id])
  end

  def update
    @participating_dojo = @taikai.participating_dojos.find(params[:id])

    if @participating_dojo.update(participating_dojo_params)
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit
    end
  end

  def destroy
    @participating_dojo = @taikai.participating_dojos.find(params[:id])

    @participating_dojo.destroy
    redirect_to controller: 'taikais', action: 'edit', id: @taikai
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
