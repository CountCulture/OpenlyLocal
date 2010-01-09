class HyperlocalSitesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :new, :create]
  before_filter :find_hyperlocal_site, :except => [:index, :new, :create]
  
  def index
    @title = "UK Hyperlocal Sites"
    @hyperlocal_sites = HyperlocalSite.all
  end
  
  def show
    @title = @hyperlocal_site.title
  end
  
  def new
    @hyperlocal_site = HyperlocalSite.new
  end
  
  def create
    @hyperlocal_site = HyperlocalSite.new(params[:hyperlocal_site])
    @hyperlocal_site.save!
    flash[:notice] = "Hyperlocal site successfully submitted"
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
