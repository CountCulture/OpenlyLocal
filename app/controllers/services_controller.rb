class ServicesController < ApplicationController
  def index
    if @council = Council.find_by_id(params[:council_id])
      @services = @council.services.matching_term(params[:term])
      @title = params[:term] ? "Links to Services named '#{params[:term]}'" : "Links to Services"
    else
      @ldg_service = LdgService.find(params[:ldg_service_id])
      @services = @ldg_service.services
      @title = "#{@ldg_service.title} : #{@ldg_service.category}"
    end
    respond_to do |format|
      format.html do
        @services = @services.group_by(&:category).sort_by{ |c| c[0] }
      end
      format.xml { render :xml => @services.to_xml }
      format.json { render :json => @services.to_json }
    end
  end
end
