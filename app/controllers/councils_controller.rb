class CouncilsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :spending, :show_spending, :accounts]
  before_filter :linked_data_available, :only => :show
  before_filter :find_council, :except => [:index, :new, :create, :spending]
  caches_action :index, :spending, :expires_in => 12.hours, :cache_path => Proc.new { |controller| controller.params }

  caches_action :show, :cache_path => Proc.new {|c| [c.instance_variable_get(:@council).cache_key,c.params[:format]].join('.') }, :if => Proc.new {|c| c.instance_variable_get(:@council) }

  caches_page :show_spending
  
  def index
    # Improperly encoded URLs will put &amp; instead of &.
    @councils = Council.find_by_params(params.except(:controller, :action, :format, :callback, :_, :amp))
    @title = 
      case 
      when params[:show_open_status]
        "UK Councils Open Data Scoreboard"
      when params[:show_1010_status]
        "UK Councils 10:10 Scoreboard"
      else
        "All UK Local Authorities/Councils"
      end
    @title += " With Opened Up Data" unless params[:include_unparsed]||params[:show_open_status]||params[:show_1010_status]
    @title += " :: #{params[:region]||params[:country]}" if params[:region]||params[:country]
    @title += " With '#{params[:term]}' in name" if params[:term]
    html_template = params[:show_open_status] ? 'open' : 'index'
    html_template = '1010' if params[:show_1010_status]
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
    @recent_planning_applications = @council.planning_applications.recent
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
    if @council.save
      flash[:notice] = "Successfully created council"
      redirect_to council_path(@council)
    else
      render :action => "new"
    end
  end
  
  def edit
  end
  
  def update
    if @council.update_attributes(params[:council])
      flash[:notice] = "Successfully updated council"
      redirect_to council_path(@council)
    else
      render :action => 'edit'
    end
  end
  
  def accounts
    @accounts = @council.account_lines.group_by(&:classification)
    @title = "Most Recent Budget"
  end
  
  def spending
    @councils = Council.all(:include => :spending_stat).select{ |c| !c.spending_stat.blank? && c.spending_stat.total_spend.to_i > 0 }
    @spending_data = Council.cached_spending_data
    @title = "Council Spending Dashboard"
  end
  
  def show_spending
    @suppliers = @council.suppliers.all(:joins => :spending_stat, :order => 'spending_stats.total_spend DESC', :limit => 10)
    @financial_transactions = @council.financial_transactions.all(:order => 'value DESC', :limit => 10)
    @spending_stat = @council.spending_stat
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
