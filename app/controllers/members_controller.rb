class MembersController < ApplicationController
  before_filter :add_rdfa_headers, :only => :show

  def show
    @member = Member.find(params[:id])
    @council = @member.council
    @committees = @member.committees
    @forthcoming_meetings = @member.forthcoming_meetings
    @title = @member.full_name
    respond_to do |format|
      format.html
      format.xml { render :xml => @member.to_xml }
      format.json { render :xml => @member.to_json }
      format.ics do
        @forthcoming_meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @forthcoming_meetings.to_ical(:name => "OpenlyLocal :: #{@title} forthcoming meetings", :url => member_url(@member), :attribute_aliases => {:event_uid => :uid})
      end
    end
  end
end
