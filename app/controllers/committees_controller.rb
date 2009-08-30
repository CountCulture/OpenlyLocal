class CommitteesController < ApplicationController
  before_filter :add_rdfa_headers, :only => :show
  
  def index
    @council = Council.find(params[:council_id])
    @committees = @council.committees
    @documents = @council.meeting_documents.all(:limit => 11)
    @meetings = @council.meetings.forthcoming.all(:limit => 11)
    @title = "Committees"
    respond_to do |format|
      format.html
      format.xml { render :xml => @committees.to_xml }
      format.json { render :json => @committees.to_json }
    end
  end
  
  def show
    @committee = Committee.find(params[:id])
    @council = @committee.council
    @title = @committee.title
    @meetings = @committee.meetings
    @documents = @committee.meeting_documents
    respond_to do |format|
      format.html
      format.xml { render :xml => @committee.to_xml(:include => [:members, :meetings]) }
      format.json { render :json => @committee.to_json(:include => [:members, :meetings]) }
      format.ics do
        @meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @meetings.to_ical(:name => "#{@title} meetings :: #{@council.title} :: OpenlyLocal", :url => committee_url(@committee), :attribute_aliases => {:event_uid => :uid})
      end
    end
  end
  
end
