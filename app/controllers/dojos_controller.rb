class DojosController < ApplicationController
  def index
    @dojos = Dojo.all.order(shortname: :asc)
  end

  def new
    @dojo = Dojo.new
    @countries = ISO3166::Country.pluck(:alpha2, :name)
end

  def create
    @dojo = Dojo.new(dojo_params)

    if @dojo.save
      redirect_to action: 'index'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @dojo = Dojo.find(params[:id])
    @countries = ISO3166::Country.pluck(:alpha2, :name)
  end

  def update
    @dojo = Dojo.find(params[:id])

    if @dojo.update(dojo_params)
      redirect_to action: 'index'
    else
    end
  end

  def destroy
    @dojo = Dojo.find(params[:id])

    if @dojo.destroy
      redirect_to action: 'index'
    else
      # TODO: I18n
      flash[:alert] = "Unable to remove dojo '#{@dojo.shortname}', it probably still has an associated Taikai"
      redirect_to action: 'index'
    end
  end

  private

  def dojo_params
    params
      .require(:dojo)
      .permit(
        :shortname,
        :name,
        :city,
        :country_code
      )
  end
end
