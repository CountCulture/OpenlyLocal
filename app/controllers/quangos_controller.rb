class QuangosController < ApplicationController
  def show
    @quango = Quango.find(params[:id])
    @title = "#{@quango.title} :: Quangos"
  end
end
