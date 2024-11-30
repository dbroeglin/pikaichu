class TachisController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo

  def index
    @tachis = @participating_dojo.tachis
  end

  private

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end
end
