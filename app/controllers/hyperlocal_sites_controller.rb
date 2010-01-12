class HyperlocalSitesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :new, :create]
  before_filter :find_hyperlocal_site, :except => [:index, :new, :create]
  before_filter :enable_google_maps, :except => [:update, :create, :destroy]
  
  def index
    if params[:location]
      @title = "UK Hyperlocal Sites nearest to #{params[:location]}"
      @hyperlocal_sites = HyperlocalSite.approved.find(:all, :origin => params[:location], :order => "distance")
    else
      @title = "UK Hyperlocal Sites"
      @hyperlocal_sites = HyperlocalSite.approved
    end
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @hyperlocal_sites.to_xml(:except => [:email, :approved]) }
      format.json { render :json => @hyperlocal_sites.to_json(:except => [:email, :approved]) }
    end
  end
  
  def show
    @title = @hyperlocal_site.title
  end
  
  def new
    @hyperlocal_site = HyperlocalSite.new(:distance_covered => 10)
    @enable_google_maps = true
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
    redirect_to hyperlocal_sites_url
  end
  
  private
  def find_hyperlocal_site
    @hyperlocal_site = HyperlocalSite.find(params[:id])
  end
end
