class MeetingsController < ApplicationController
  
  def index
    @council = Council.find(params[:council_id]) 
    build_title
    @meetings = params[:include_past] ? @council.meetings : @council.meetings.forthcoming
    respond_to do |format|
      format.html
      format.xml { render :xml => @meetings.to_xml }
      format.json { render :xml => @meetings.to_json }
      format.ics do
        @meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @meetings.to_ical(:name => "OpenlyLocal :: #{@title}", :url => "http://openlylocal.com/meetings", :attribute_aliases => {:event_uid => :uid})
      end 
    end
  end
  
  def show
    @meeting = Meeting.find(params[:id])
    @council = @meeting.council
    @committee = @meeting.committee
    @other_meetings = @committee.meetings - [@meeting]
    @title = "#{@meeting.title}, #{@meeting.date_held.to_s(:event_date).squish}"
    respond_to do |format|
      format.html
      format.xml { render :xml => @meeting.to_xml }
      format.json { render :json => @meeting.to_json }
    end
  end
  
  def build_title
    @title = params[:include_past] ? "All Committee Meetings" : "Forthcoming Committee Meetings"
  end
end
