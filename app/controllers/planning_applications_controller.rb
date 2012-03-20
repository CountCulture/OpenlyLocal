class PlanningApplicationsController < ApplicationController
  before_filter :enable_google_maps, :only => [:show, :index]
  before_filter :show_rss_link, :only => :index
  before_filter :find_planning_application, :only => :show
  caches_action :show, :cache_path => Proc.new {|c| [c.instance_variable_get(:@planning_application).cache_key,c.params[:format]].join('.') }, 
                       :if => Proc.new {|c| c.instance_variable_get(:@planning_application) }, 
                       :expires_in  => 12.hours
  
  def index
    if @council = params[:council_id]&&Council.find_by_id(params[:council_id])
      order = params[:order]||(params[:format].to_s == 'rss') ? 'updated_at DESC' : 'start_date DESC'
      page = params[:page] || 1
      @planning_applications = @council.planning_applications.with_details.paginate(:order => order, :page => page.to_i )
      @page_title = "Latest Planning Applications"
      @title = "Latest Planning Applications in #{@council.title}"
    elsif @postcode = Postcode.find_from_messy_code(params[:postcode])
      distance = 0.2
      @planning_applications = PlanningApplication.find(:all, :origin => [@postcode.lat, @postcode.lng], 
                                                              :within => distance)
      @title = "Planning Applications within #{distance} km of #{params[:postcode]}"
    end
    @message = "Sorry. No matching Planning Applications" if @planning_applications.blank?
    @message = "Sorry. Postcode not found" if @postcode.blank? && params[:postcode]

    respond_to do |format|
      format.html
      format.xml { render :xml => @planning_applications.to_xml }
      format.json { render :json => @planning_applications.to_json }
      format.rss { render :layout => false }
    end
  end
  
  def overview
    @title = 'UK Planning Applications'
  end
  
  def show
    @council = @planning_application.council
    @title = @planning_application.title
    respond_to do |format|
      format.html
      format.xml { render :xml => @planning_application.to_xml }
      format.json { render :json => @planning_application.to_json }
    end
  end
  
  protected
  def find_planning_application
    @planning_application = PlanningApplication.find(params[:id])
  end
end
