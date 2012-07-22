class MembersController < ApplicationController
  before_filter :linked_data_available, :only => :show
  before_filter :authenticate, :except => [:show, :index]
  before_filter :enable_google_maps, :only => :show
  
  def index
    @title = params[:include_ex_members] ? "Current and former members" : "Current members"
    if @council = Council.find_by_id(params[:council_id])
      @members = params[:include_ex_members] ? @council.members.all(:include => [:ward, :twitter_account]) : @council.members.current.all(:include => [:ward, :twitter_account])
    else
      @members = Member.except_vacancies.current.paginate(:page => params[:page], :order => "last_name", :include => [:council, :ward, :twitter_account])
      @title += " :: Page #{(params[:page]||1).to_i}"
    end
    respond_to do |format|
      format.html
      format.xml do
        if @council 
         render :xml => @members.to_xml(:include => [:council, :ward, :twitter_account])
        else
         render :xml => @members.to_xml(:include => [:council, :ward, :twitter_account]) { |xml|
                    xml.tag! 'total-entries', @members.total_entries
                    xml.tag! 'per-page', @members.per_page
                    xml.tag! 'page', (params[:page]||1).to_i
                  }
        end
      end
      format.json do
        if @council 
          render :json => @members.to_json(:include => [:council, :ward, :twitter_account])
        else
          render :json => { :page => (params[:page]||1).to_i,
                            :per_page => @members.per_page,
                            :total_entries => @members.total_entries,
                            :members => @members.to_json(:include => [:council, :ward, :twitter_account])
                          }
                
        end
      end
    end
  end
  
  def show
    @member = Member.find(params[:id])
    @council = @member.council
    @committees = @member.committees
    @forthcoming_meetings = @member.committees.forthcoming_meetings
    @title = @member.full_name
    api_options = {:except => [:ward_id], :include => [:ward, :committees], :methods => :forthcoming_meetings}
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
