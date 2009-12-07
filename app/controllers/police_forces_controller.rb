class PoliceForcesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :linked_data_available, :only => [:show]
  
  def index
    @police_forces = PoliceForce.find(:all)
    @title = "UK Police Forces"
    respond_to do |format|
      format.html
      format.xml { render :xml => @police_forces.to_xml }
      format.json { render :json => @police_force.to_json }
    end
  end
  
  def show
    @police_force = PoliceForce.find(params[:id])
    @title = @police_force.name
    respond_to do |format|
      includes = {:councils => {:only => [:id, :name, :url], :methods => :openlylocal_url}}
      format.html
      format.xml { render :xml => @police_force.to_xml(:include => includes) }
      format.rdf 
      format.json { render :as_json => @police_force.to_xml(:include => includes) }
    end
  end
  
  def new
    @police_force = PoliceForce.new    
  end
  
  def create
    @police_force = PoliceForce.new(params[:police_force])
    @police_force.save!
    flash[:notice] = "Successfully created police force"
    redirect_to police_force_path(@police_force)
  rescue
    render :action => "new"
  end
  
  def edit
    @police_force = PoliceForce.find(params[:id])
  end
  
  def update
    @police_force = PoliceForce.find(params[:id])
    @police_force.update_attributes!(params[:police_force])
    flash[:notice] = "Successfully updated police force"
    redirect_to police_force_path(@police_force)
  rescue
    render :action => "edit"
  end
  
end
