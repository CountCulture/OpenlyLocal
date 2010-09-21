class QuangosController < ApplicationController

  def index
    @quangos = Quango.all
    @title = 'Quangos and other organisations'
    respond_to do |format|
      format.html
      format.xml { render :xml => @quangos.to_xml }
      format.json { render :json => @quangos.to_json }
    end
  end
  
  def show
    @quango = Quango.find(params[:id])
    @title = "#{@quango.title} :: Quangos"
  end
end
