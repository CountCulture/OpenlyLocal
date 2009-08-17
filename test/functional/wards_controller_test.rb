require 'test_helper'

class WardsControllerTest < ActionController::TestCase

  def setup# do
    @ward = Factory(:ward)
    @council = @ward.council
    @member = Factory(:member, :council => @council)
    @ward.members << @member
  end

  # show test
   context "on GET to :show" do
     
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
   
   # edit tests
   context "on get to :edit a scraper without auth" do
     setup do
       get :edit, :id => @ward.id
     end

     should_respond_with 401
   end

   context "on get to :edit a scraper" do
     setup do
       stub_authentication
       get :edit, :id => @ward.id
     end

     should_assign_to :ward
     should_respond_with :success
     should_render_template :edit
     should_not_set_the_flash
     should "display a form" do
      assert_select "form#edit_ward_#{@ward.id}"
     end
     

     should "show button to delete ward" do
       assert_select "form.button-to[action='/wards/#{@ward.to_param}']"
     end
   end

   # update tests
   context "on PUT to :update without auth" do
     setup do
       put :update, { :id => @ward.id, 
                      :ward => { :uid => 44, 
                                 :name => "New name"}}
     end

     should_respond_with 401
   end

   context "on PUT to :update" do
     setup do
       stub_authentication
       put :update, { :id => @ward.id, 
                      :ward => { :uid => 44, 
                                 :name => "New name"}}
     end

     should_assign_to :ward
     should_redirect_to( "the show page for ward") { ward_path(@ward.reload) }
     should_set_the_flash_to "Successfully updated ward"

     should "update ward" do
       assert_equal "New name", @ward.reload.name
     end
   end

   # delete tests
   context "on delete to :destroy a ward without auth" do
     setup do
       delete :destroy, :id => @ward.id
     end

     should_respond_with 401
   end

   context "on delete to :destroy a ward" do

     setup do
       stub_authentication
       delete :destroy, :id => @ward.id
     end

     should "destroy ward" do
       assert_nil Ward.find_by_id(@ward.id)
     end
     should_redirect_to ( "the council page") { council_url(@council) }
     should_set_the_flash_to "Successfully destroyed ward"
   end
end
