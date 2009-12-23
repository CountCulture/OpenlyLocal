class HyperlocalSitesController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_hyperlocal_site
  
  def show
    @title = @hyperlocal_site.title
  end
  
  def edit
    
  end
  
  def update
    @hyperlocal_site.update_attributes!(params[:hyperlocal_site])
    flash[:notice] = "Successfully updated HyperLocal site"
    
    redirect_to hyperlocal_site_url(@hyperlocal_site)
  end
  
  private
  def find_hyperlocal_site
    @hyperlocal_site = HyperlocalSite.find(params[:id])
  end
end
