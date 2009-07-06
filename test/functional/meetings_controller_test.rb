require 'test_helper'

class MeetingsControllerTest < ActionController::TestCase
  
  def setup
    @committee = Factory(:committee)
    @council = @committee.council
    @other_committee = Factory(:committee, :title => "Another Committee", :council => @council)
    @member = Factory(:member, :council => @council)
    @meeting = Factory(:meeting, :council => @council, :committee => @committee)
    @future_meeting = Factory(:meeting, :date_held => 3.days.from_now.to_date, :council => @council, :committee => @committee, :uid => @meeting.uid+1)
    @other_committee_meeting = Factory(:meeting, :date_held => 4.days.from_now.to_date, :council => @council, :committee => @other_committee, :uid => @meeting.uid+2)
    @committee.members << @member
  end
  
  # index tests
  context "on GET to :index for council" do
    
    context "with basic request" do
      setup do
        get :index, :council_id => @council.id
      end
  
      should_assign_to(:council) { @council } 
      should_assign_to(:meetings) { [@future_meeting, @other_committee_meeting] }
      should_respond_with :success
      should_render_template :index
      should_respond_with_content_type 'text/html'
      
      should "list forthcoming meetings" do
        assert_select "#meetings ul a", @future_meeting.title
      end
      
      should "have title" do
        assert_select "title", /Forthcoming Committee Meetings/
      end
    end
        
    context "and include_past meetings requested" do
      setup do
        get :index, :council_id => @council.id, :include_past => true
      end
  
      should_assign_to(:meetings) { [@meeting, @future_meeting, @other_committee_meeting] }
      should_respond_with :success
      
      should "list all meetings" do
        assert_select "#meetings ul a", @meeting.title
        assert_select "#meetings ul a", @future_meeting.title
      end
      
      should "have title" do
        assert_select "title", /All Committee Meetings/
      end
    end
    
    # context "and restricted to a committee" do
    #   setup do
    #     get :index, :council_id => @council.id, :committee_id => @other_committee.id
    #   end
    #   
    #   should_assign_to(:meetings) { [@other_committee_meeting] }
    #   should_respond_with :success
    #   
    #   should "have title" do
    #     assert_select "title", /Meetings for Another Committee/
    #   end
    # end
    
    context "with xml requested" do
      setup do
        get :index, :council_id => @council.id, :format => "xml"
      end
  
      should_assign_to(:council) { @council } 
      should_assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
    end
    
    context "with json requested" do
      setup do
        get :index, :council_id => @council.id, :format => "json"
      end
  
      should_assign_to(:council) { @council } 
      should_assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
    end
    
    context "with ics requested" do
      setup do
        get :index, :council_id => @council.id, :format => "ics"
      end
  
      should_assign_to(:council) { @council } 
      should_assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'text/calendar'
    end
    
  end

  # show tests
  context "on GET to :show" do
    
    context "with basic request" do
      setup do
        get :show, :id => @meeting.id
      end

      should_assign_to :meeting, :committee
      should_assign_to(:other_meetings) { [@future_meeting] }
      should_respond_with :success
      should_render_template :show
     
      should "show committee in title" do
        assert_select "title", /#{@committee.title}/
      end
      
      should "show meeting date in title" do
        assert_select "title", /#{@meeting.date_held.to_s(:event_date).squish}/
      end
      
      should "list members" do
        assert_select "#members ul a", @member.title
      end
    
      should "list other meetings" do
        assert_select "#other_meetings"
      end
      
      should "not show minutes" do
        assert_select "#minutes_extract", false
      end
    end
    
    context "when meeting has minutes" do
      setup do
        @document = Factory(:document, :document_owner => @meeting)
        get :show, :id => @meeting.id
      end

      should "show link to minutes" do
        assert_select "a", /minutes/i
      end
      
      should "show minutes" do
        assert_select "#minutes_extract"
      end
    end
    
    context "with xml request" do
      setup do
        get :show, :id => @meeting.id, :format => "xml"
      end
    
      should_assign_to :meeting
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
    end
    
    context "with json request" do
      setup do
        get :show, :id => @meeting.id, :format => "json"
      end
    
      should_assign_to :meeting
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
      
    end
    
  end  
end
