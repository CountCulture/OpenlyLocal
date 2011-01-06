require 'test_helper'

class MeetingsControllerTest < ActionController::TestCase
  
  def setup
    @committee = Factory(:committee)
    @council = @committee.council
    @other_committee = Factory(:committee, :title => "Another Committee", :council => @council)
    @member = Factory(:member, :council => @council)
    @meeting = Factory(:meeting, :council => @council, :committee => @committee)
    @future_meeting = Factory(:meeting, :date_held => 3.days.from_now.to_date, :council => @council, :committee => @committee)
    @other_committee_meeting = Factory(:meeting, :date_held => 4.days.from_now.to_date, :council => @council, :committee => @other_committee)
    @cancelled_committee_meeting = Factory(:meeting, :date_held => 8.days.from_now.to_date, :council => @council, :committee => @other_committee, :status => "cancelled")
    @committee.members << @member
  end
  
  # routing tests
  should "route with council to index" do
    assert_routing("councils/42/meetings", {:controller => "meetings", :action => "index", :council_id => "42"})
    assert_routing("councils/42/meetings.xml", {:controller => "meetings", :action => "index", :council_id => "42", :format => "xml"})
    assert_recognizes( {:controller => "meetings", :action => "index"}, "meetings") # check existing route still works
    assert_recognizes( {:controller => "meetings", :action => "index", :format => "xml"}, "meetings.xml") # check existing route still works
  end
  
  should "route to show" do
    assert_routing("meetings/42", {:controller => "meetings", :action => "show", :id => "42"})
  end

  # index tests
  context "on GET to :index for council" do
    
    context "with basic request" do
      setup do
        get :index, :council_id => @council.id
      end
  
      should assign_to(:council) { @council } 
      should assign_to(:meetings) { [@future_meeting, @other_committee_meeting] }
      should respond_with :success
      should render_template :index
      should respond_with_content_type 'text/html'
      
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
  
      should assign_to(:meetings) { [@meeting, @future_meeting, @other_committee_meeting, @cancelled_committee_meeting] }
      should respond_with :success
      
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
    #   should assign_to(:meetings) { [@other_committee_meeting] }
    #   should respond_with :success
    #   
    #   should "have title" do
    #     assert_select "title", /Meetings for Another Committee/
    #   end
    # end
    
    context "with xml requested" do
      context "in general" do
        setup do
          get :index, :council_id => @council.id, :format => "xml"
        end
        should assign_to(:council) { @council } 
        should assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
        should respond_with :success
        should_render_without_layout
        should respond_with_content_type 'application/xml'
        should "show status of meeting" do
          assert_select "meetings>meeting>status" do
            assert_select "status", 2
          end
        end
      end
  
      context "and include_past meetings requested" do
        setup do
          get :index, :council_id => @council.id, :include_past => true, :format => "xml"
        end
        should assign_to(:council) { @council } 
        should assign_to(:meetings) { [@meeting, @future_meeting, @other_committee_meeting, @cancelled_committee_meeting]}
        should respond_with :success
        should_render_without_layout
        should respond_with_content_type 'application/xml'
        should "show status of meeting" do
          assert_select "meetings>meeting>status" do
            assert_select "status", :text => /cancelled/, :count => 1
          end
        end
      end
  
    end
    
    context "with json requested" do
      setup do
        get :index, :council_id => @council.id, :format => "json"
      end
  
      should assign_to(:council) { @council } 
      should assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
    end
    
    context "with ics requested" do
      setup do
        get :index, :council_id => @council.id, :format => "ics"
      end
  
      should assign_to(:council) { @council } 
      should assign_to(:meetings) { [@future_meeting, @other_committee_meeting]}
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'text/calendar'
    end
    
  end

  # show tests
  context "on GET to :show" do
    
    context "with basic request" do
      setup do
        get :show, :id => @meeting.id
      end

      should assign_to :meeting, :committee
      should assign_to(:other_meetings) { [@future_meeting] }
      should respond_with :success
      should render_template :show
     
      should "show committee in title" do
        assert_select "title", /#{@committee.title}/
      end
      
      should "show meeting date in title" do
        assert_select "title", /#{@meeting.date_held.to_s(:event_date).squish}/
      end
      
      should "list members of committee" do
        assert_select "#committee_members ul a", @member.title
      end
    
      should "list other meetings" do
        assert_select "#other_meetings"
      end
      
      should "not show minutes" do
        assert_select "#minutes_extract", false
      end
      
      should "show link to resource uri in head" do
        assert_select "link[rel*='primarytopic'][href*='/id/meetings/#{@meeting.id}']"
      end

    end
    
    context "when meeting has minutes" do
      setup do
        @document = Factory(:document, :document_owner => @meeting, :document_type => "Minutes")
        get :show, :id => @meeting.id
      end

      should "show link to minutes" do
        assert_select "a", /minutes/i
      end
      
      should "show minutes" do
        assert_select "#minutes_extract"
      end
    end
    
    context "when meeting is cancelled" do
      should "show alert" do
        @meeting.update_attribute(:status, "cancelled")
        get :show, :id => @meeting.id
        assert_select "h4.alert", /cancelled/i
      end
    end
    
    context "when meeting has related articles" do
      should "show them" do
        related_article = Factory(:related_article, :subject => @meeting)
        get :show, :id => @meeting.id
        assert_select "#related_articles a", /#{related_article.title}/i
      end
    end
    
    context "with xml request" do
      context "in general" do
        setup do
          get :show, :id => @meeting.id, :format => "xml"
        end

        should assign_to :meeting
        should respond_with :success
        should_render_without_layout
        should respond_with_content_type 'application/xml'
      end
      context "when meeting is cancelled" do
        should "show status is cancelled if meeting is cancelled" do
          @meeting.update_attribute(:status, "cancelled")
          get :show, :id => @meeting.id, :format => "xml"
          assert_select "meeting status", /cancelled/
        end
      end
    end
    
    context "with json request" do
      setup do
        get :show, :id => @meeting.id, :format => "json"
      end
    
      should assign_to :meeting
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
    end
    
    context "with rdf requested" do
      setup do
        get :show, :id => @meeting.id, :format => "rdf"
      end

      should assign_to(:meeting) { @meeting }
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/rdf+xml'

      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
        assert_match /rdf:RDF.+ xmlns:vcal/m, @response.body
      end

      should "show basic rdf info for meeting" do
        assert_match /rdf:Description.+rdf:about.+\/id\/meetings\/#{@meeting.id}/, @response.body
        assert_match /rdf:Description.+rdfs:label>#{@meeting.title}/m, @response.body
        assert_match /rdf:type.+openlylocal:meeting/m, @response.body
        assert_match /rdf:type.+vcal:Vevent/m, @response.body
      end
      
      should "show detailed event info for meeting" do
        assert_match /rdf:type.+vcal:summary.+#{@meeting.title}/m, @response.body
        assert_match /rdf:type.+vcal:dtstart.+#{@meeting.date_held.to_s(:vevent)}/m, @response.body
        assert_match /rdf:type.+vcal:location.+#{@meeting.venue}/m, @response.body
        
      end
      
      should "show meeting as primary resource" do
        assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/meetings\/#{@meeting.id}/m, @response.body
      end
      
       should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/meetings\/#{@meeting.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/meetings\/#{@meeting.id}\"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/meetings\/#{@meeting.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/meetings\/#{@meeting.id}.xml/m, @response.body
      end
      
      should "show committee relationship" do
        assert_match /rdf:Description.+\/committees\/#{@committee.id}.+openlylocal:meeting.+\/meetings\/#{@meeting.id}/m, @response.body
      end
    end
  end  
end
