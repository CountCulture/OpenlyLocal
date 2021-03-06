require File.expand_path('../../test_helper', __FILE__)

class CommitteesControllerTest < ActionController::TestCase
  def setup
    @committee = Factory(:committee)
    @council = @committee.council
    @member = Factory(:member, :council => @council)
    @meeting = Factory(:meeting, :council => @council, :committee => @committee)
    @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 1.week.from_now)
    @committee.members << @member
    @document = Factory(:document, :document_owner => @meeting)
    Factory.create(:committee, :council_id => @council.id, :title => "another committee" )
    Factory.create(:committee, :council_id => Factory(:another_council).id, :title => "another council's committee" )    
  end
  
  # show test
   context "on GET to :show" do
     
     context "with basic request" do
       setup do
         get :show, :id => @committee.id
       end

       should assign_to :committee
       should respond_with :success
       should render_template :show
      
       should "show committee in title" do
         assert_select "title", /#{@committee.title}/
       end
       
       should "show council in title" do
         assert_select "title", /#{@committee.council.title}/
       end
       
       should "list members" do
         assert_select "div#members li a", @member.title
       end
     
       should "list meetings" do
         assert_select "div#meetings li a", @meeting.title
       end
       
       should "list meeting documents for committee" do
         assert_select "div#documents li a", @document.extended_title
       end
       
       should "show link to resource uri in head" do
         assert_select "link[rel='primarytopic'][href*='/id/committees/#{@committee.id}']"
       end

       should "not show link to ward" do
         assert_select ".extra_info a", :text => /ward committee/i, :count => 0
       end
     end
     
     context "with basic request when committee has associated ward" do
       setup do
         @ward = Factory(:ward, :council => @committee.council)
         @ward.committees << @committee
         get :show, :id => @committee.id
       end

       should assign_to :committee
       should respond_with :success
       should render_template :show
      
       should "show link to ward" do
         assert_select ".extra_info a", /#{@ward.name}/
       end
     end
     
     context "when committee has related articles" do
       should "show them" do
         related_article = Factory(:related_article, :subject => @committee)
         get :show, :id => @committee.id
         assert_select "#related_articles a", /#{related_article.title}/i
       end
     end

     context "with xml request" do
       setup do
         get :show, :id => @committee.id, :format => "xml"
       end

       should assign_to :committee
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/xml'
       
       should "include members in response" do
         assert_select "committee member"
       end
       
       should "include meetings in response" do
         assert_select "committee meeting"
       end
       
       should "include council in response" do
         assert_select "committee>council>name", @committee.council.name
       end
     end
     
     context "with json request" do
       setup do
         get :show, :id => @committee.id, :format => "json"
       end

       should assign_to :committee
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/json'
       
       should "include members in response" do
         assert_match /committee\":.+members\":/, @response.body
       end
       
       should "include meetings in response" do
         assert_match /committee\":.+meetings\":/, @response.body
       end
       
       should "include council in response" do
         assert_match /committee\":.+council\":/, @response.body
       end
     end
     
     context "with ics requested" do
       setup do
         get :show, :id => @committee.id, :format => "ics"
       end

       should assign_to(:committee) { @committee }
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'text/calendar'
     end
     
     context "with rdf request" do
       setup do
         get :show, :id => @committee.id, :format => "rdf"
       end

       should assign_to(:committee) { @committee }
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/rdf+xml'

       should "show rdf headers" do
         assert_match /rdf:RDF.* xmlns:foaf/m, @response.body
         assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
         assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
       end

       should "show uri of committee resource" do
         assert_match /rdf:Description.+rdf:about.+\/id\/committees\/#{@committee.id}/, @response.body
       end

       should "show committee as primary resource" do
         assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/committees\/#{@committee.id}/m, @response.body
       end

       should "show rdf info for committee" do
         assert_match /rdf:Description.+rdf:about.+\/committees\/#{@committee.id}/, @response.body
         assert_match /rdf:Description.+rdfs:label>#{@committee.title}/m, @response.body
         assert_match /rdf:type.+openlylocal:LocalAuthorityCommittee/m, @response.body
       end

       should "show members" do
         assert_match /foaf:member.+rdf:resource.+\/members\/#{@member.id}/, @response.body
       end
       
       should "show meetings" do
         assert_match /openlylocal:meeting.+rdf:resource.+\/meetings\/#{@meeting.id}/, @response.body
       end
       
       should "show council relationship" do
         assert_match /rdf:Description.+\/councils\/#{@council.id}.+openlylocal:LocalAuthorityCommittee.+\/committees\/#{@committee.id}/m, @response.body
       end

     end
   end  

   # index test
   context "on GET to :index with council_id" do

     context "with basic request" do
       setup do
         @another_active_committee = Factory(:committee, :council => @council)
         @meeting_in_past_for_another_active_committee = Factory(:meeting, :council => @council, :committee => @another_active_committee)
         @inactive_committee = Factory(:committee, :council => @council)
         get :index, :council_id => @council.id
       end

       should assign_to :committees
       should assign_to(:council) { @council }
       should respond_with :success
       should render_template :index

       should "show council in title" do
         assert_select "title", /#{@council.title}/
       end

       should "should list active committees for council" do
         assert_select "#committees li", 2 do #active committees by default
           assert_select "a", @committee.title
           assert_select "a", :text => @inactive_committee.title, :count => 0
         end
       end
       
       should "should list next meeting for committees" do
         assert_select "#committees li a.meeting_link", 1
       end
       
       should "list committee meetings for council" do
         assert_select "div#meetings li a", @forthcoming_meeting.title
       end
       
       should "list committee documents for council" do
         assert_select "div#documents li a", @document.extended_title
       end
       
       should "show link to include inactive committees" do
         assert_select "a[href*=include_inactive]", /include inactive/i
       end
     end

     context "when inactive included" do
       setup do
         @inactive_committee = Factory(:committee, :council => @council)
         get :index, :council_id => @council.id, :include_inactive => true
       end

       should assign_to :committees
       should assign_to(:council) { @council }
       should respond_with :success
       should render_template :index

       should "not show link to include inactive committees" do
         assert_select "a[href*=include_inactive]", :text =>/include inactive/i, :count =>0
       end
 
       should "should include list committees for council" do
         assert_select "#committees li", 3 do #active committees by default
           assert_select "a.active", @committee.title
           assert_select "a.inactive", @inactive_committee.title
         end
       end
       
     end

     context "with xml requested" do
       setup do
         get :index, :council_id => @council.id, :format => "xml"
       end

       should assign_to :committees
       should assign_to(:council) { @council }
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/xml'
       
       should "list committees" do
         assert_select "committees>committee>title", @committee.title
       end
       
       should "list members of committees" do
         assert_select "committees>committee>members>member>first-name", @member.first_name
       end
       
       should "include council in response" do
         assert_select "committees>committee>council>name", @council.name
       end
     end

     context "with json requested" do
       setup do
         get :index, :council_id => @council.id, :format => "json"
       end

       should assign_to :committees
       should assign_to(:council) { @council }
       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/json'
       
       should "list committees" do
         assert_match /committees\":.+title\":\"#{@committee.title}/, @response.body
       end
       
       should "list members of committees" do
         assert_match /committees\":.+members\":.+first_name\":\"#{@member.first_name}/, @response.body
       end
       
       should "list council of committees" do
         assert_match /committees\":.+council\":.+name\":\"#{@council.name}/, @response.body
       end
     end

   end
   
   context "on GET to :index without council_id" do

     # should respond_with :failure
     should "raise an exception" do
       assert_raise(ActiveRecord::RecordNotFound) { get :index }
     end
   end
   
end
