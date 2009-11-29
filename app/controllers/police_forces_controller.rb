class PoliceForcesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]

  def index
    @police_forces = PoliceForce.find(:all)
  end
  
  def show
    @police_force = PoliceForce.find(params[:id])
  end
  
  def new
    @police_force = PoliceForce.new    
  end
  
  def create
    @police_force = PoliceForce.new(params[:police_force])
    @police_force.save!
    flash[:notice] = "Successfully created portal system"
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
