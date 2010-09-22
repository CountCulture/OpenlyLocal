class QuangosController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :find_quango, :except => [:index, :new, :create]

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
  
  def new
    @quango = Quango.new    
  end
  
  def create
    @quango = Quango.new(params[:quango])
    @quango.save!
    flash[:notice] = "Successfully created quango"
    redirect_to quango_url(@quango)
  rescue
    render :action => "new"
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
  
  def destroy
    @quango.destroy
    flash[:notice] = "Successfully destroyed Quango"
    redirect_to quangos_url
  end
  
  private
  def find_quango
    @quango = Quango.find(params[:id])
  end
end
