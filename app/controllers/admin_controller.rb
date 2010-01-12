class AdminController < ApplicationController
  before_filter :authenticate

  def index
    @title = 'Admin'
    @hyperlocal_sites = HyperlocalSite.find_all_by_approved(false)
  end

end
