class PollsController < ApplicationController
  # before_filter :linked_data_available, :only => :show
  
  def index
    @council = Council.find(params[:council_id]) if params[:council_id]
    @polls = Poll.associated_with_council(@council).paginate(:page => valid_page, :order => "date_held DESC, created_at DESC")
    @title = (@council ? "Election Results" : "All Local Authority election polls") + " :: Page #{valid_page}"
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @polls.to_xml(:include => [:area]) { |xml|
                    xml.tag! 'total-entries', @polls.total_entries
                    xml.tag! 'per-page', @polls.per_page
                    xml.tag! 'page', valid_page
                  }
      end
      format.json {render :json => { :page => valid_page,
                         :per_page => @polls.per_page,
                         :total_entries => @polls.total_entries,
                         :polls => @polls.to_json(:include => [:area])
                       }}
    end
  end
  
  def show
    @poll = Poll.find(params[:id])
    @council = @poll.area.council
    @title = "Election for #{@poll.position} for #{@poll.area.title} #{@poll.area.class} on #{@poll.date_held.to_s(:event_date)}"
    @total_votes = @poll.candidacies.all.sum{ |c| c.votes.to_i }
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @poll.to_xml(:include => [:area, :candidacies]) }
      format.json { render :json => @poll.to_json(:include => [:area, :candidacies])}
      format.rdf
    end
  end
end
