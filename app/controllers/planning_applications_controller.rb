class PlanningApplicationsController < ApplicationController
  before_filter :enable_google_maps, :only => [:show]
  
  def overview
    @title = 'UK Planning Applications'
  end
  
  def show
    @planning_application = PlanningApplication.find(params[:id])
    @council = @planning_application.council
    @title = @planning_application.title
  end
end
