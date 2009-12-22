class PoliceAuthoritiesController < ApplicationController
  def show
    @police_authority = PoliceAuthority.find(params[:id])
    @title = @police_authority.name
    respond_to do |format|
      includes = {:councils => {:only => [:id, :name, :url], :methods => :openlylocal_url}}
      format.html
      format.xml { render :xml => @police_authority.to_xml(:include => includes) }
      format.rdf 
      format.json { render :as_json => @police_authority.to_xml(:include => includes) }
    end
    
  end
end
