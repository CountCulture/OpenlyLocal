class ServicesController < ApplicationController
  def index
    @council = Council.find(params[:council_id])
    @services = @council.services.group_by(&:category).sort_by{ |c| c[0] }
    @title = "Links to Services"
  end
end
