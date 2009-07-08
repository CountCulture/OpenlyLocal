class MembersController < ApplicationController
  
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
    end
  end
end
