class FeedEntriesController < ApplicationController
  
  def index
    @feed_entries = params[:tagged_with].blank? ? FeedEntry.restrict_to(params[:restrict_to]).paginate(:page => valid_page) : 
                                                  FeedEntry.restrict_to(params[:restrict_to]).tagged_with(params[:tagged_with]).paginate(:page => valid_page)

    @title  = 'Latest news stories'
    @title += " from #{params[:restrict_to].humanize}" if params[:restrict_to]
    @title += " tagged with '#{params[:tagged_with]}'" if params[:tagged_with]
    @title += " :: Page #{valid_page}"
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @feed_entries.to_xml { |xml|
          xml.tag! 'total-entries', @feed_entries.total_entries
          xml.tag! 'per-page', @feed_entries.per_page
          xml.tag! 'page', valid_page
        } 
      end
      format.json do
        render :json => { :page => valid_page,
                          :per_page => @feed_entries.per_page,
                          :total_entries => @feed_entries.total_entries,
                          :feed_entries => @feed_entries.to_json
                        }
      end
    end
  end
end
