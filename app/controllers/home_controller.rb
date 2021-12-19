class HomeController < ApplicationController
  def index
    @num_taikais = Taikai.count
    @num_dojos = Dojo.count
  end
end
