class PoliceAuthoritiesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :linked_data_available, :only => [:show]
  before_filter :find_police_authority, :except => :index

  def index
    @police_authorities = PoliceAuthority.all
    @title = "UK Police Authorities"
    respond_to do |format|
      format.html
      format.xml { render :xml => @police_authorities.to_xml }
      format.json { render :json => @police_authorities.to_json }
    end
  end
  
  def show
    @title = @police_authority.name
    respond_to do |format|
      includes = {:councils => {:only => [:id, :name, :url], :methods => :openlylocal_url}}
      format.html
      format.xml { render :xml => @police_authority.to_xml(:include => includes) }
      format.rdf 
      format.json { render :as_json => @police_authority.to_xml(:include => includes) }
    end
  end
  
  def edit
  end
  
  def update
    if @police_authority.update_attributes(params[:police_authority])
      flash[:notice] = "Successfully updated police authority"
      redirect_to police_authority_url(@police_authority)
    else
      render :action => 'edit'
    end
  end
  
  private
  def find_police_authority
    @police_authority = PoliceAuthority.find(params[:id])
  end
end
