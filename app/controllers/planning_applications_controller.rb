class PlanningApplicationsController < ApplicationController
  before_filter :enable_google_maps, :only => [:show, :index]
  before_filter :show_rss_link, :only => :index
  before_filter :find_planning_application, :only => :show
  before_filter :authenticate, :only => [:admin]
  caches_action :show, :cache_path => Proc.new {|c| [c.instance_variable_get(:@planning_application).cache_key,c.params[:format]].join('.') }, 
                       :if => Proc.new {|c| c.instance_variable_get(:@planning_application) }, 
                       :expires_in  => 12.hours
  caches_action :index, :expires_in => 4.hours, :cache_path => Proc.new { |controller| controller.params }

  def admin
    @councils = Council.find(:all, :include => { :scrapers => { :parser => :portal_system, :council => {} } }, 
                                   :order => "councils.name", 
                                   :conditions=> 'parsers.result_model = "PlanningApplication"')
    @councils_with_problem_scrapers, @councils_with_good_scrapers = @councils.partition{ |c| c.scrapers.any?{ |s| s.problematic? } }
    @planning_parsers = @councils.collect{ |c| c.scrapers.collect(&:parser).select{ |p| p.portal_system_id } }.flatten.uniq
    @latest_alert_subscribers = AlertSubscriber.all(:limit => 5, :order => 'created_at DESC')
  end
  
  def index
    if @council = params[:council_id] && Council.find_by_id(params[:council_id])
      order = params[:order]||(params[:format].to_s == 'rss') ? 'updated_at DESC' : 'start_date DESC'
      page = params[:page] || 1
      @planning_applications = @council.planning_applications.with_details.paginate(:order => order, :page => page.to_i )
      @page_title = "Latest Planning Applications"
      @title = "Latest Planning Applications in #{@council.title}"
    elsif @postcode = Postcode.find_from_messy_code(params[:postcode])
      distance = if %w(0.2 0.8).include? params[:distance]
        params[:distance].to_f
      else
        0.2
      end
      # bounds=Geokit::Bounds.from_point_and_radius(@postcode, distance)
      # @planning_applications = PlanningApplication.find(:all, :bounds => bounds)

      # @todo after switch to PostGIS, paginate and sort, like when searching by council ID
      @planning_applications = PlanningApplication.find(:all, :origin => [@postcode.lat, @postcode.lng], 
                                                              :within => distance)
      @title = "Planning Applications within #{distance} km of #{params[:postcode]}"
    end

    if @planning_applications.blank?
      @message = if @postcode.blank? && params[:postcode]
        "Sorry. Postcode not found."
      else
        "Sorry. No matching planning applications."
      end
    end

    respond_to do |format|
      format.html
      format.xml do
        if @planning_applications.blank?
          render :xml => @message, :status => :unprocessable_entity
        else
          render :xml => @planning_applications.to_xml
        end
      end
      format.json do
        if @planning_applications.blank?
          render :json => @message, :status => :unprocessable_entity
        else
          render :as_json => @planning_applications.to_xml
        end
      end
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
      format.xml { render :xml => @planning_application.to_detailed_xml }
      format.json { render :as_json => @planning_application.to_detailed_xml }
    end
  end

  protected

  def find_planning_application
    @planning_application = PlanningApplication.find(params[:id])
  end
end
