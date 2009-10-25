class ServicesController < ApplicationController
  def index
    @council = Council.find(params[:council_id])
    @services = @council.services.matching_term(params[:term])
    @title = params[:term] ? "Links to Services named '#{params[:term]}'" : "Links to Services"
    respond_to do |format|
      format.html do
        @services = @services.group_by(&:category).sort_by{ |c| c[0] }
      end
      format.xml { render :xml => @services.to_xml }
      format.json { render :json => @services.to_json }
    end
  end
end
