class MembersController < ApplicationController
  before_filter :add_rdfa_headers, :only => :show

  def show
    @member = Member.find(params[:id])
    @council = @member.council
    @committees = @member.committees
    @forthcoming_meetings = @member.forthcoming_meetings
    @title = @member.full_name
    api_options = {:except => [:ward_id], :include => [:ward, :committees, :forthcoming_meetings]}
    respond_to do |format|
      format.html
      format.xml { render :xml => @member.to_xml(api_options)}
      format.json { render :json => @member.to_json(api_options) }
      format.ics do
        @forthcoming_meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @forthcoming_meetings.to_ical(:name => "#{@title} forthcoming meetings :: #{@council.title} :: OpenlyLocal", :url => member_url(@member), :attribute_aliases => {:event_uid => :uid})
      end
    end
  end
end
