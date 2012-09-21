class PoliceForcesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :linked_data_available, :only => [:show]
  before_filter :find_police_force, :except => [:index, :new, :create]
  
  def index
    @police_forces = PoliceForce.find(:all, :include => [:twitter_account])
    @title = "UK Police Forces"
    respond_to do |format|
      format.html
      format.xml { render :xml => @police_forces.to_xml( :except => :npia_id ) }
      format.json { render :json => @police_force.to_json( :except => :npia_id ) }
    end
  end
  
  def show
    @title = @police_force.name
    respond_to do |format|
      includes = {:councils => {:only => [:id, :name, :url], :methods => :openlylocal_url}}
      format.html
      format.xml { render :xml => @police_force.to_xml(:include => includes, :except => :npia_id) }
      format.rdf 
      format.json { render :as_json => @police_force.to_xml(:include => includes, :except => :npia_id) }
    end
  end
  
  def new
    @police_force = PoliceForce.new    
  end
  
  def create
    @police_force = PoliceForce.new(params[:police_force])
    if @police_force.save
      flash[:notice] = "Successfully created police force"
      redirect_to police_force_url(@police_force)
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @police_force.update_attributes(params[:police_force])
      flash[:notice] = "Successfully updated police force"
      redirect_to police_force_url(@police_force)
    else
      render :action => 'edit'
    end
  end
  
  private
  def find_police_force
    @police_force = PoliceForce.find(params[:id])
  end
end
