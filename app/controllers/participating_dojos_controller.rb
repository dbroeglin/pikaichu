class ParticipatingDojosController < ApplicationController

  def edit
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:id])
  end

  def update
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:id])

    if @participating_dojo.update(participating_dojo_params)
      redirect_to controller: 'taikais', action: 'edit', id: @taikai
    else
      render :edit
    end
  end

  def destroy
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:id])

    @participating_dojo.destroy
    redirect_to controller: 'taikais', action: 'edit', id: @taikai
  end

  private

  def participating_dojo_params
    params.require(:participating_dojo).permit(:taikai_id, :dojo_id, :display_name)
  end
end
