class CouncilsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :linked_data_available, :only => :show
  caches_action :index, :show
  def index
    @councils = Council.find_by_params(params.except(:controller, :action, :format))
    @title = params[:include_unparsed] ? "All UK Local Authorities/Councils" : "UK Local Authorities/Councils With Opened Up Data"
    @title += " With Term '#{params[:term]}'" if params[:term]
    @title += " With SNAC id '#{params[:snac_id]}'" if params[:snac_id]
    respond_to do |format|
      format.html
      format.xml { render :xml => @councils.to_xml(:include => nil) }
      format.json { render :json =>  @councils.to_json }
      format.rdf
    end
  end
  
  def show
    @council = Council.find(params[:id])
    @members = @council.members.current
    @committees = @council.active_committees
    @meetings = @council.meetings.forthcoming.all(:limit => 11)
    @documents = @council.past_meeting_documents.all(:limit => 11)
    @wards = @council.wards
    # @datapoints = @council.datapoints.select{ |d| d.summary }
    @party_breakdown = @council.party_breakdown
    respond_to do |format|
      format.html
      format.xml { render :xml => @council.to_detailed_xml }
      format.json { render :as_json => @council.to_detailed_xml }
      format.rdf
    end
  end
  
  def new
    @council = Council.new
  end
  
  def create
    @council = Council.new(params[:council])
    @council.save!
    flash[:notice] = "Successfully created council"
    redirect_to council_path(@council)
  rescue
    render :action => "new"
  end
  
  def edit
    @council = Council.find(params[:id])
  end
  
  def update
    @council = Council.find(params[:id])
    @council.update_attributes!(params[:council])
    flash[:notice] = "Successfully updated council"
    redirect_to council_path(@council)
  rescue
    render :action => "edit"
  end
  
end
