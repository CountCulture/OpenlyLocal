require 'test_helper'

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

       should_assign_to :committee
       should_respond_with :success
       should_render_template :show
      
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
       
       should "show rdfa headers" do
         assert_select "html[xmlns:foaf*='xmlns.com/foaf']"
       end

       should "show rdfa stuff in head" do
         assert_select "head link[rel*='foaf']"
       end

       should "show rdfa typeof" do
         assert_select "div[typeof*='twfyl:LocalAuthorityCommittee']"
       end

       should "use member name as foaf:name" do
         assert_select "h1 span[property*='foaf:name']", @committee.title
       end

       should "show rdfa attributes for members" do
         assert_select "#members li a[rel*='foaf:member']"
       end
       
       should "show foaf attributes for meetings" do
         assert_select "#meetings li[rel*='twfyl:meeting']"
       end
     end
     
     context "with xml request" do
       setup do
         get :show, :id => @committee.id, :format => "xml"
       end

       should_assign_to :committee
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/xml'
       
       should "include members in response" do
         assert_select "committee member"
       end
       
       should "include meetings in response" do
         assert_select "committee meeting"
       end
     end
     
     context "with json request" do
       setup do
         get :show, :id => @committee.id, :format => "json"
       end

       should_assign_to :committee
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/json'
       
       should "include members in response" do
         assert_match /committee\":.+members\":/, @response.body
       end
       should "include meetings in response" do
         assert_match /committee\":.+meetings\":/, @response.body
       end
     end
     
   end  

   # index test
   context "on GET to :index with council_id" do

     context "with basic request" do
       setup do
         get :index, :council_id => @council.id
       end

       should_assign_to :committees
       should_assign_to(:council) { @council }
       should_respond_with :success
       should_render_template :index

       should "show council in title" do
         assert_select "title", /#{@council.title}/
       end

       should "should list committees for council" do
         assert_select "#committees li", 2 do
           assert_select "a", @committee.title
         end
       end
       
       should "list committee meetings for council" do
         assert_select "div#meetings li a", @forthcoming_meeting.title
       end
       
       should "list committee documents for council" do
         assert_select "div#documents li a", @document.extended_title
       end
       
     end

     context "with xml requested" do
       setup do
         get :index, :council_id => @council.id, :format => "xml"
       end

       should_assign_to :committees
       should_assign_to(:council) { @council }
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/xml'
     end

     context "with json requested" do
       setup do
         get :index, :council_id => @council.id, :format => "json"
       end

       should_assign_to :committees
       should_assign_to(:council) { @council }
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/json'
     end

   end
   
   context "on GET to :index without council_id" do

     # should_respond_with :failure
     should "raise an exception" do
       assert_raise(ActiveRecord::RecordNotFound) { get :index }
     end
   end
   
end
