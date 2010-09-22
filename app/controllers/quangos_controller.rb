class QuangosController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :find_quango, :except => [:index]

  def index
    @quangos = Quango.all(:order => 'title')
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
  
  
  def edit
  end
  
  def update
    @quango.update_attributes!(params[:quango])
    flash[:notice] = "Successfully updated quango"
    redirect_to quango_url(@quango)
  rescue
    render :action => "edit"
  end
  
  private
  def find_quango
    @quango = Quango.find(params[:id])
  end
end
