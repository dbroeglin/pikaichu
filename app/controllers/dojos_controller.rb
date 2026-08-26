class DojosController < ApplicationController
  after_action :verify_authorized

  def index
    authorize Dojo
    @dojos = Dojo.all.order(shortname: :asc).page params[:page]
  end

  def new
    authorize Dojo
    @dojo = Dojo.new
    @countries = ISO3166::Country.pluck(:alpha2, :iso_short_name)
  end

  def edit
    @dojo = authorize Dojo.find(params[:id])
    @countries = ISO3166::Country.pluck(:alpha2, :iso_short_name)
  end

  def create
    authorize Dojo
    @dojo = Dojo.new(dojo_params)

    if @dojo.save
      redirect_to action: "index"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @dojo = authorize Dojo.find(params[:id])

    if @dojo.update(dojo_params)
      redirect_to action: "index"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dojo = authorize Dojo.find(params[:id])

    unless @dojo.destroy
      # TODO: I18n
      flash[:alert] = "Unable to remove dojo '#{@dojo.shortname}', it probably still has an associated Taikai"
    end
    redirect_to action: "index", status: :see_other
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
