class CouncilsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :spending, :show_spending]
  before_filter :linked_data_available, :only => :show
  before_filter :find_council, :except => [:index, :new, :create, :spending]
  caches_action :index, :show, :cache_path => Proc.new { |controller| controller.params }
  
  def index
    @councils = Council.find_by_params(params.except(:controller, :action, :format, :callback))
    @title = params[:show_open_status] ? "UK Councils Open Data Scoreboard" : "All UK Local Authorities/Councils"
    @title += " With Opened Up Data" unless params[:include_unparsed]||params[:show_open_status]
    @title += " :: #{params[:region]||params[:country]}" if params[:region]||params[:country]
    # @title = "UK Councils Open Data scoreboard" if params[:show_open_status]
    @title += " With '#{params[:term]}' in name" if params[:term]
    html_template = params[:show_open_status] ? 'open' : 'index'
    respond_to do |format|
      format.html { render html_template }
      format.xml { render :xml => @councils.to_xml(:include => nil) }
      format.json { render :as_json =>  @councils.to_xml(:include => nil) }
      format.rdf
    end
  end
  
  def show
    @members = @council.members.current(:include => [:twitter_account])
    @committees = @council.active_committees
    @meetings = @council.meetings.forthcoming.all(:limit => 11)
    @documents = @council.meeting_documents.all(:limit => 11)
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
  
  def spending
    @councils = Council.all(:joins => :suppliers, :group => "councils.id")
    @suppliers = Supplier.all(:joins => :spending_stat, :order => 'spending_stats.total_spend DESC', :limit => 10)
    @financial_transactions = FinancialTransaction.all(:order => 'value DESC', :limit => 10)
    @title = "Council Spending Dashboard"
  end
  
  def show_spending
    @suppliers = @council.suppliers.all(:joins => :spending_stat, :order => 'spending_stats.total_spend DESC', :limit => 10)
    @financial_transactions = @council.financial_transactions.all(:order => 'value DESC', :limit => 10)
    @title = "Spending Dashboard"
  end
  
  private
  def find_council
    includes = {:wards => [:output_area_classification]}
    @council = 
    case 
    when params[:snac_id]
      Council.find_by_snac_id(params[:snac_id], :include => includes)
    when params[:os_id]
      Council.find_by_os_id(params[:os_id], :include => includes)
    else
      Council.find(params[:id], :include => includes)
    end
  end
  
end
