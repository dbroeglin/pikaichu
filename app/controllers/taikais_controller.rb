class TaikaisController < ApplicationController
  layout 'taikai', :except => [:index, :new, :create]

  def index
    @taikais =
      Taikai.all
            .order(start_date: :desc, end_date: :desc, shortname: :asc)
            .includes(:participants)
            .page params[:page]
    @taikais = @taikais.per params[:per] if params[:per]
  end

  def show
    @taikai =
      Taikai.includes(
        {
          participating_dojos: [
            { teams: { participants: { scores: :results } } },
            { participants: [{ scores: :results }, :kyudojin] }
          ]
        },
        staffs: :user
      ).find(params[:id])
  end

  def new
    @taikai = Taikai.new
  end

  def edit
    @taikai = Taikai.includes([participating_dojos: :dojo], { staffs: [:role, :user] }).find(params[:id])
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
    ActiveRecord::Base.transaction do
      Result
        .joins(score: { participant: :participating_dojo })
        .where("participating_dojos.taikai_id": @taikai.id)
        .delete_all
      Score
        .joins(participant: :participating_dojo)
        .where("participating_dojos.taikai_id": @taikai.id)
        .delete_all
      Score
        .joins(team: :participating_dojo)
        .where("participating_dojos.taikai_id": @taikai.id)
        .delete_all

      @taikai.destroy!
    end

    redirect_to action: 'index', status: :see_other
  end

  def export
    @taikai =
      Taikai
      .includes({ participating_dojos: [{ teams: { participants: { scores: :results } } },
                                        { participants: { scores: :results } }] }, :staffs)
      .find(params[:id])

    render xlsx: 'export', filename: "Taikai - #{@taikai.shortname}.xlsx"
  end

  def generate
    ActiveRecord::Base.transaction do
      @taikai = Taikai.create_from_2in1(params[:id], current_user, "part2", "partie 2", params[:bracket_size].to_i)
    end

    if @taikai.errors.empty?
      redirect_to action: 'show', id: @taikai.id, status: :see_other
    else
      flash[:alert] = @taikai.errors.full_messages.join("; ")
      redirect_to action: 'show', status: :see_other
    end
  end

  def transition_to
    raise unless TaikaiStateMachine.states.include?(params[:state])

    @taikai = authorize Taikai.find(params[:id])

    @taikai.current_user = current_user
    @taikai.transition_to! params[:state]

    redirect_to action: 'show', id: @taikai.id, status: :see_other
  rescue Statesman::GuardFailedError
    flash.now[:alert] = [
      I18n.translate('templates.taikai_state_transitions_errors.message',
                     target_state: t("activerecord.states.taikai.#{params[:state]}")),
      I18n.translate("#{@taikai.current_state}_#{params[:state]}",
                     scope: [:templates, :taikai_state_transitions_errors], default: ""),
    ].join " "
    render :show, status: :unprocessable_entity
  end

  private

  def taikai_params
    params
      .require(:taikai)
      .permit(
        :category,
        :description,
        :distributed,
        :end_date,
        :form,
        :scoring,
        :name,
        :num_targets,
        :shortname,
        :start_date,
        :tachi_size,
        :total_num_arrows,
      )
  end
end
