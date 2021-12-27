class TaikaisController < ApplicationController
  def index
    @taikais = Taikai.all.order(start_date: :asc, end_date: :asc, shortname: :asc)
  end

  def new
    @taikai = Taikai.new
  end

  def create
    @taikai = Taikai.new(taikai_params)

    if @taikai.save
      redirect_to action: 'index'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @taikai = Taikai.find(params[:id])
  end

  def update
    @taikai = Taikai.find(params[:id])

    if @taikai.update(taikai_params)
      redirect_to action: 'index'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @taikai = Taikai.find(params[:id])
    @taikai.destroy

    redirect_to action: 'index'
  end

  def export
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])

    render xlsx: "export", filename: "Taikai - #{@taikai.shortname}.xlsx"
  end

  private

  def taikai_params
    params.require(:taikai).permit(
      :shortname,
      :name,
      :description,
      :start_date,
      :end_date,
      :distributed,
      :individual,
    )
  end
end
