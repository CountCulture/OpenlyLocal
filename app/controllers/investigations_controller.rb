class InvestigationsController < ApplicationController
  
  def index
    @investigations = Investigation.all
    @title = "Standards Investigations & Reports"
    respond_to do |format|
      format.html
      format.xml { render :xml => @investigations.to_xml }
      format.json { render :as_json => @investigations.to_xml }
    end
  end
  
  def show
    @investigation = Investigation.find(params[:id])
    @title = "#{@investigation.title} :: Standards Investigations & Reports"
    respond_to do |format|
      # includes = {:councils => {:only => [:id, :name, :url], :methods => :openlylocal_url}}
      format.html
      format.xml { render :xml => @investigation.to_xml}#(:include => includes) }
      # format.rdf 
      format.json { render :as_json => @investigation.to_xml}#(:include => includes) }
    end
    
  end
end
