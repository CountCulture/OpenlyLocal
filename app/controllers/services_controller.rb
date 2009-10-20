class ServicesController < ApplicationController
  def index
    @council = Council.find(params[:council_id])
    @services = @council.services.group_by(&:category)
    @title = "Links to Services"
  end
end
