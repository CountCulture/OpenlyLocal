require 'test_helper'

class WardsControllerTest < ActionController::TestCase
  # show test
   context "on GET to :show" do
     
     setup do
       @ward = Factory(:ward)
       @council = @ward.council
       @member = Factory(:member, :council => @council)
       @ward.members << @member
     end

     context "with basic request" do
       setup do
         get :show, :id => @ward.id
       end

       should_assign_to :ward
       should_respond_with :success
       should_render_template :show
      
       should "show ward in title" do
         assert_select "title", /#{@ward.title}/
       end
       
       should "show council in title" do
         assert_select "title", /#{@ward.council.title}/
       end
       
       should "list members" do
         assert_select "div#members li a", @member.title
       end
     
     end
     
     context "with xml request" do
       setup do
         get :show, :id => @ward.id, :format => "xml"
       end

       should_assign_to :ward
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/xml'
       
       should "include members in response" do
         assert_select "ward member"
       end
       
     end
     
     context "with json request" do
       setup do
         get :show, :id => @ward.id, :format => "json"
       end

       should_assign_to :ward
       should_respond_with :success
       should_render_without_layout
       should_respond_with_content_type 'application/json'
       
       should "include members in response" do
         assert_match /ward\":.+members\":/, @response.body
       end
     end
     
   end  
end
