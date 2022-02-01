class TaikaisController < ApplicationController
  def index
    @taikais =
      Taikai.all.order(start_date: :asc, end_date: :asc, shortname: :asc)
  end

  def show
    @taikai =
      Taikai.includes(
        {
          participating_dojos: [
            { teams: { participants: :results }},
            { participants: [:results, :kyudojin] }
          ]
        },
        staffs: :user
      ).find(params[:id])
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
    @taikai = Taikai.includes([participating_dojos: :dojo], { staffs: [:role, :user] }).find(params[:id])
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

    redirect_to action: 'index', status: :see_other
  end

  def export
    @taikai =
      Taikai
      .includes({ participating_dojos: [{ teams: { participants: :results } }, { participants: [:results] }] }, :staffs)
      .find(params[:id])

    render xlsx: 'export', filename: "Taikai - #{@taikai.shortname}.xlsx"
  end

  def generate
    @taikai = Taikai.create_from_2in1(params[:id], current_user, "partie2", "partie 2")

    if @taikai.errors.empty?
      redirect_to action: 'show', id: @taikai.id, status: :see_other
    else
      flash[:alert] = @taikai.errors.full_messages.join("; ")
      redirect_to action: 'show', status: :see_other
    end
  end

  private

  def taikai_params
    params
      .require(:taikai)
      .permit(
        :description,
        :distributed,
        :end_date,
        :form,
        :name,
        :num_targets,
        :shortname,
        :start_date,
        :tachi_size,
        :total_num_arrows,
      )
  end
end
