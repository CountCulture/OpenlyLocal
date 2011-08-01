class PlanningApplicationsController < ApplicationController
  
  def show
    @planning_application = PlanningApplication.find(params[:id])
    @council = @planning_application.council
    @title = @planning_application.title
  end
end
