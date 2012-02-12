class HyperlocalSitesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :new, :create, :custom_search_results]
  before_filter :find_hyperlocal_site, :except => [:index, :new, :create, :custom_search_results, :destroy_multiple, :admin]
  before_filter :enable_google_maps, :except => [:update, :create, :destroy]
  before_filter :show_rss_link, :only => :index
  caches_action :index, :cache_path => Proc.new { |controller| controller.params }, :expires_in => 12.hours
  caches_page :show
  
  def index
    @title = params[:independent] ? "Independent " : ""
    @title += "Hyperlocal Sites"
    unless params[:location].blank?
      @title += " nearest to #{params[:location]}"
      begin
        @location = Geokit::LatLng.normalize(params[:location])
        @hyperlocal_sites = HyperlocalSite.approved.find(:all, :origin => @location, :order => 'distance', :limit => 10)
      rescue Geokit::Geocoders::GeocodeError => e
        @message = "Sorry, couldn't find location: #{params[:location]}"
        @hyperlocal_sites = HyperlocalSite.approved
      end
    else
      @hyperlocal_sites = HyperlocalSite.country(params[:country]).region(params[:region]).independent(params[:independent]).approved
      @title += " in #{(params[:region]||params[:country]||'UK & Ireland')}"
    end
    @cse_label = "openlylocal_cse_hyperlocal_" + params[:location].to_s.gsub(/\W/,'').downcase
    respond_to do |format|
      format.html
      format.xml do
        xml_render_params = params[:custom_search] ? { :template => "hyperlocal_sites/custom_search.xml.builder" } : { :xml => @hyperlocal_sites.to_xml(:except => [:email, :approved]) }
        render xml_render_params
      end
      format.json { render :json => @hyperlocal_sites.to_json(:except => [:email, :approved]) }
      format.rss { render :layout => false }
    end
  end
  
  def show
    @title = "#{@hyperlocal_site.title} :: UK & Ireland Hyperlocal Sites"
  end
  
  def new
    @hyperlocal_site = HyperlocalSite.new(:distance_covered => 3)
    @enable_google_maps = true
    @title = "New Hyperlocal Site"
  end
  
  def create
    @hyperlocal_site = HyperlocalSite.new(params[:hyperlocal_site])
    @hyperlocal_site.save!
    flash[:notice] = "Hyperlocal site successfully submitted. We will review it ASAP and will <a href='http://twitter.com/OpenlyLocal'>tweet</a> when it is approved"
    redirect_to hyperlocal_sites_url
  rescue
    render :action => "new"
  end
  
  def edit
    @enable_google_maps = true
  end
  
  def update
    @hyperlocal_site.update_attributes!(params[:hyperlocal_site])
    @hyperlocal_site.update_attribute(:approved, params[:hyperlocal_site][:approved])
    flash[:notice] = "Successfully updated HyperLocal site"
    
    redirect_to hyperlocal_site_url(@hyperlocal_site)
  end
  
  def destroy
    @hyperlocal_site.destroy
    flash[:notice] = "Successfully destroyed HyperLocal site"
    redirect_to admin_hyperlocal_sites_url
  end
  
  def destroy_multiple
    @hyperlocal_sites = HyperlocalSite.destroy_all(:id => params[:ids])
    flash[:notice] = "Successfully destroyed #{@hyperlocal_sites.size} HyperLocal sites"
    redirect_to admin_hyperlocal_sites_url
  end
  
  def custom_search_results
    @title = "UK Hyperlocal Sites Search Results"
  end
  
  def admin
    @hyperlocal_sites = HyperlocalSite.find_all_by_approved(false)
  end
  
  private
  def find_hyperlocal_site
    @hyperlocal_site = HyperlocalSite.find(params[:id])
  end
end
