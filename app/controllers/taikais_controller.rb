class TaikaisController < ApplicationController
  def index
    @taikais =
      Taikai.all.order(start_date: :asc, end_date: :asc, shortname: :asc)
  end

  def show
    @taikai =
      Taikai
        .includes(participating_dojos: %i[teams participants])
        .find(params[:id])
    @staffs = @taikai.staffs.ordered
  end

  def new
    @taikai = Taikai.new
  end

  def create
    @taikai = Taikai.new(taikai_params)
    @taikai.current_user = current_user

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
    @taikai = authorize Taikai.find(params[:id])

    if @taikai.update(taikai_params)
      redirect_to action: 'index'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @taikai = authorize Taikai.find(params[:id])
    @taikai.destroy

    redirect_to action: 'index'
  end

  def draw
    @taikai =
      Taikai
        .includes(participating_dojos: :participants)
        .find(params[:id])

      if @taikai.individual?
        @taikai.participating_dojos.each do |participating_dojo|
          participating_dojo.participants.update_all(index: nil)
          participating_dojo.participants.shuffle.each_with_index do |participant, index|
            participant.index = index + 1
          end
          participating_dojo.participants.each do |participant|
            participant.save!
          end
        end
      else
        @taikai.participating_dojos.each do |participating_dojo|
          participating_dojo.teams.update_all(index: nil)
          participating_dojo.teams.shuffle.each_with_index do |team, index|
            team.index = index + 1
          end
          participating_dojo.teams.each do |team|
            team.save!
          end
        end
    end
  end

  def export
    @taikai =
      Taikai
        .includes(participating_dojos: { participants: [:results] })
        .find(params[:id])

    render xlsx: 'export', filename: "Taikai - #{@taikai.shortname}.xlsx"
  end

  private

  def taikai_params
    params
      .require(:taikai)
      .permit(
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
