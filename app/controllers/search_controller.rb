class SearchController < ApplicationController
  def kyudojins
    @kyudojins = Kyudojin.containing(params[:q]&.strip).limit(15)

    render layout: false
  end

  def users
    set_taikai
    @staff = @taikai.staffs.find_by_id(params[:staff_id])
    @users = User.containing(params[:q]&.strip)
                 .where.not(id: (@taikai.staffs.joins(:user).pluck("users.id") - [@staff&.user_id]))
                 .limit(15)

    render layout: false
  end

  def dojos
    set_taikai
    @participating_dojo = @taikai.participating_dojos.find_by_id(params[:participating_dojo_id])

    @dojos = Dojo.containing(params[:q]&.strip)
                 .where.not(id: (@taikai.participating_dojos.pluck(:dojo_id) - [@participating_dojo&.dojo_id]))
                 .limit(15)

    render layout: false
  end

  private

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end
end
