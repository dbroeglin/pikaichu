class DojosController < ApplicationController
  def index
    @dojos = Dojo.all.order(shortname: :asc)
  end

  def new
    @dojo = Dojo.new
  end

  def create
    @dojo = Dojo.new(dojo_params)

    if @dojo.save
      redirect_to action: 'index'
    else
      render :new
    end
  end

  def edit
    @dojo = Dojo.find(params[:id])
  end

  def update
    @dojo = Dojo.find(params[:id])

    if @dojo.update(dojo_params)
      redirect_to action: 'index'
    else
      render :edit
    end
  end

  def destroy
    @dojo = Dojo.find(params[:id])
    @dojo.destroy

    redirect_to action: 'index'
  end

  private

  def dojo_params
    params
      .require(:dojo)
      .permit(
        :shortname,
        :name,
        :country_code
      )
  end
end
