class MainController < ApplicationController
  caches_action :index
  def index
    @page_title           = "Openly Local :: Making Local Government More Transparent"
    @councils             = Council.parsed({}).find(:all, :order => "councils.updated_at DESC", :limit => 10)
    @forthcoming_meetings = Meeting.forthcoming.all(:limit => 5)
    @latest_councillors   = Member.all(:order => "created_at DESC", :limit => 10)
    @news_items           = FeedEntry.for_blog.all(:limit => 3)
  end

end
