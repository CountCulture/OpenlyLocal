class MainController < ApplicationController
  caches_action :index
  def index
    @councils             = Council.parsed.find(:all, :order => "councils.updated_at DESC", :limit => 10)
    @forthcoming_meetings = Meeting.forthcoming.all(:limit => 5)
    @latest_councillors   = Member.all(:order => "created_at DESC", :limit => 10)
  end

end
