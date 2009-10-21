class ServicesController < ApplicationController
  def index
    @council = Council.find(params[:council_id])
    @services = @council.services.matching_term(params[:term]).group_by(&:category).sort_by{ |c| c[0] }
    @title = params[:term] ? "Links to Services named '#{params[:term]}'" : "Links to Services" 
  end
end
