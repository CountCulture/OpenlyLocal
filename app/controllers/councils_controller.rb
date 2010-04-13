class CouncilsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :linked_data_available, :only => :show
  before_filter :find_council, :except => [:index, :new, :create]
  caches_action :index, :show, :cache_path => Proc.new { |controller| controller.params }
  
  def index
    @councils = Council.find_by_params(params.except(:controller, :action, :format))
    @title = "All UK Local Authorities/Councils"
    @title += " in #{params[:region]||params[:country]}" if params[:region]||params[:country]
    @title += " With Opened Up Data" unless params[:include_unparsed]
    @title += " With '#{params[:term]}' in name" if params[:term]
    respond_to do |format|
      format.html
      format.xml { render :xml => @councils.to_xml(:include => nil) }
      format.json { render :json =>  @councils.to_json }
      format.rdf
    end
  end
  
  def show
    @members = @council.members.current
    @committees = @council.active_committees
    @meetings = @council.meetings.forthcoming.all(:limit => 11)
    @documents = @council.meeting_documents.all(:limit => 11)
    @wards = @council.wards
    @party_breakdown = @council.party_breakdown
    @page_description = "Information and statistics about #{@council.title}"
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
  end
  
  def update
    @council.update_attributes!(params[:council])
    flash[:notice] = "Successfully updated council"
    redirect_to council_path(@council)
  rescue
    render :action => "edit"
  end
  
  private
  def find_council
    @council = 
    case 
    when params[:snac_id]
      Council.find_by_snac_id(params[:snac_id])
    when params[:os_id]
      Council.find_by_os_id(params[:os_id])
    else
      Council.find(params[:id])
    end
  end
  
end
