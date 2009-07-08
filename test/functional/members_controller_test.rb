require 'test_helper'

class MembersControllerTest < ActionController::TestCase
  
  # show test
   context "on GET to :show" do
     setup do
       @member = Factory(:member)
       @council = @member.council
       @committee = Factory(:committee, :council => @council)
       @member.committees << @committee
       @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 2.days.from_now)
     end
     context "with basic request" do
       setup do
         get :show, :id => @member.id
       end

       should_assign_to(:member) { @member }
       should_assign_to(:council) { @council }
       should_assign_to :committees
       should_assign_to(:forthcoming_meetings) { [@forthcoming_meeting] }
       should_respond_with :success
       should_render_template :show
       should_respond_with_content_type 'text/html'
       should "show member name in title" do
         assert_select "title", /#{@member.full_name}/
       end
       should "list committee memberships" do
         assert_select "#committees ul a", @committee.title
       end
       should "list forthcoming meetings" do
         assert_select "#meetings ul a", @forthcoming_meeting.title
       end
       should "show link to meeting calendar" do
         assert_select "#meetings a.calendar[href*='#{@member.id}.ics']"
       end
     end
     
     context "with xml requested" do
       setup do
         get :show, :id => @member.id, :format => "xml"
       end

       should_assign_to(:member) { @member }
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/xml'
     end

     context "with json requested" do
       setup do
         get :show, :id => @member.id, :format => "json"
       end

       should_assign_to(:member) { @member }
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/json'
     end

     context "with ics requested" do
       setup do
         get :show, :id => @member.id, :format => "ics"
       end

       should_assign_to(:member) { @member }
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'text/calendar'
     end
   end  

end
