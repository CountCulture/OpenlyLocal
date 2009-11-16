class MembersController < ApplicationController
  before_filter :add_rdfa_headers, :only => :show
  before_filter :authenticate, :except => [:show]

  def show
    @member = Member.find(params[:id])
    @council = @member.council
    @committees = @member.committees
    @forthcoming_meetings = @member.forthcoming_meetings
    @title = @member.full_name
    api_options = {:except => [:ward_id], :include => [:ward, :committees, :forthcoming_meetings]}
    respond_to do |format|
      format.html
      format.rdf
      format.xml { render :xml => @member.to_xml(api_options)}
      format.json { render :json => @member.to_json(api_options) }
      format.ics do
        @forthcoming_meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @forthcoming_meetings.to_ical(:name => "#{@title} forthcoming meetings :: #{@council.title} :: OpenlyLocal", :url => member_url(@member), :attribute_aliases => {:event_uid => :uid})
      end
    end
  end
  
  def edit
    @member = Member.find(params[:id])
  end
  
  def update
    @member = Member.find(params[:id])
    @member.update_attributes!(params[:member])
    flash[:notice] = "Successfully updated member"
    redirect_to member_url(@member)
  end
  
  def destroy
    @member = Member.find(params[:id])
    @member.destroy
    flash[:notice] = "Successfully destroyed member"
    redirect_to council_url(@member.council)
  end
  
end
