class TaikaisController < ApplicationController
  def index
    @taikais = Taikai.all
  end

  def show
  end

  def edit
    @taikai = Taikai.find(params[:id])
  end

  def new
  end

  def update
    @taikai = Taikai.find(params[:id])

    if @taikai.update(taikai_params)
      redirect_to @taikai
    else
      render :edit
    end
  end

  def delete
  end

  private
  def taikai_params
    params.require(:taikai).permit(:shortname, :description, :start_date, :end_date)
  end
end
