require 'test_helper'

class UserSubmissionsControllerTest < ActionController::TestCase
  
  # new test
  context "on GET to :new" do
    
    context "in general" do
      setup do
        @item = Factory(:council)
        get :new, :submission_type => 'social_networking_details', :item_type => 'Council', :item_id => @item.id
      end
      
      should assign_to(:user_submission)
      should respond_with :success
      should render_template :new
      should_render_with_layout

      should "set submission_details for user submission" do
        assert_kind_of SocialNetworkingDetails, assigns(:user_submission).submission_details
      end

      should "associate given item with user submission" do
        assert_equal @item, assigns(:user_submission).item
      end
    
      should "show title" do
        assert_select 'title', /new social networking details/i
      end

      should "show form" do
        assert_select "form#new_user_submission"
      end

      should "show fieldset" do
        assert_select "fieldset#submission_details"
      end
      
      should "show text_fields for submission_details" do
        assert_select "input#user_submission_submission_details_blog_url"
      end
      
      should 'show item as hidden field' do
        assert_select "input#user_submission_item_id[type=hidden][value=#{@item.id}]"
        assert_select "input#user_submission_item_type[type=hidden][value=Council]"
      end
      
      should 'show submission_type as hidden field' do
        assert_select "input#user_submission_submission_type[type=hidden][value=social_networking_details]"
      end
    end
    
    # context "with council_id given" do
    #   
    #   setup do
    #     @member = Factory(:member)
    #     get :new, :council_id => @member.council.id
    #   end
    #   
    #   should assign_to(:user_submission) { @user_submission }
    #   should respond_with :success
    # 
    #   should "associate council with user submission" do
    #     assert_equal @member.council, assigns(:user_submission).council
    #   end
    # 
    #   should "select council in select box" do
    #     assert_select "select#user_submission_council_id" do
    #       assert_select "option", 2 do #1 for council, 1 for blank
    #         assert_select "option[value=#{@member.council.id}]"
    #       end
    #     end
    #   end
    #   
    #   should "show list of possible members in select box" do
    #     assert_select "select#user_submission_member_id" do
    #       assert_select "option", 2 do #1 for member, 1 for blank
    #         assert_select "option[value=#{@member.id}]"
    #       end
    #     end
    #   end
    #   
    #   should "not show text_field for member name" do
    #     assert_select "input#user_submission_member_name", false
    #   end
    # end
    # 
    # context "with council_id given but no members for council" do
    #   
    #   setup do
    #     @council = Factory(:council)
    #     get :new, :council_id => @council.id
    #   end
    #   
    #   should assign_to(:user_submission) { @user_submission}
    #   should respond_with :success
    # 
    #   should "associate council with user submission" do
    #     assert_equal @council, assigns(:user_submission).council
    #   end
    # 
    #   should "select council in select box" do
    #     assert_select "select#user_submission_council_id" do
    #       assert_select "option[value=#{@council.id}]"
    #     end
    #   end
    #   
    #   should "not_show list of possible members in select box" do
    #     assert_select "select#user_submission_member_id", false
    #   end
    #   
    #   should "show text_field for member name" do
    #     assert_select "input#user_submission_member_name"
    #   end
    # end
    # 
  end
  
  # create test
   context "on POST to :create" do
     setup do
       @item = Factory(:council)
     end
    
    context "with valid params" do
       setup do
         post :create, :user_submission => { :item_id => @item.id, 
                                             :item_type => 'Council', 
                                             :submission_type => 'social_networking_details', 
                                             :submission_details => {:twitter_account_name => 'fooman'}}
       end
     
       should_change("The number of user_submissions", :by => 1) { UserSubmission.count }
       should assign_to :user_submission
       should_redirect_to( "the page for the council") { council_url(@item) }
       should set_the_flash.to /Successfully submitted/i
        
     end
  #    
  #    context "with member_id but no council" do
  #       setup do
  #         @member = Factory(:member, :council => @council)
  #         post :create, :user_submission => { :twitter_account_name => "foobar", :member_id => @member.id }
  #       end
  # 
  #       should_change("The number of user_submissions", :by => 1) { UserSubmission.count }
  #       should assign_to :user_submission
  #       should_redirect_to( "the page for the member's council") { council_url(@council) }
  #       should set_the_flash.to /Successfully submitted/i
  #       
  #       should "set the council and member for the user_submission" do
  #         user_submission = UserSubmission.find_by_twitter_account_name("foobar")
  #         assert_equal @member, user_submission.member
  #         assert_equal @council, user_submission.council
  #       end
  #     end
  
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :user_submission => {:submission_type => 'social_networking_details'}
       end
     
       should_not_change("The number of user_submissions") { UserSubmission.count }
       should assign_to :user_submission
       should render_template :new
       should_not set_the_flash
     end
    
   end
   
   # edit test
   context "on GET to :edit" do
     setup do
       @council = Factory(:council)
       @user_submission = Factory(:user_submission, :item => @council)
     end
  
     context "without auth" do
       setup do
         get :edit, :id => @user_submission.id
       end
  
       should respond_with 401
     end
  
     context "in general" do
       setup do
         stub_authentication
         get :edit, :id => @user_submission.id
       end
  
       should assign_to(:user_submission) { @user_submission}
       should respond_with :success
       should render_template :edit
       should_render_with_layout
  
       should "show title" do
         assert_select 'title', /edit submission/i
       end
  
       should "show form" do
         assert_select "form#edit_user_submission_#{@user_submission.id}"
       end
  
       should "show text_fields for submission_details" do
         assert_select "input#user_submission_submission_details_twitter_account_name[value=#{@user_submission.submission_details.twitter_account_name}]"
       end

       should 'show submission_type as hidden field' do
         assert_select "input#user_submission_submission_type[type=hidden][value=social_networking_details]"
       end
     end
   end
   
   # update tests
   context "on PUT to :update" do
     setup do
       @user_submission = Factory(:user_submission)
     end
     
     context "without auth" do
       setup do
         put :update, { :id => @user_submission.id,
                        :approve => "true" }
       end
  
       should respond_with 401
     end
  
     context "in general" do
       setup do
         stub_authentication
         put :update, { :id => @user_submission.id,
                        :user_submission => { :submission_type => 'social_networking_details', :submission_details => {:twitter_account_name => "bar", :blog_url => 'http:foo.com/blog'}}}
       end
  
       should redirect_to( "the admin page") { admin_url }
       should set_the_flash.to /Successfully updated submission/i
  
       should "update user submission" do
         assert_equal "bar", @user_submission.reload.submission_details.twitter_account_name
       end
       
       should "not mark user_submission as approved" do
         assert !@user_submission.reload.approved?
       end
     end
     
     context "when approving" do
       setup do
         stub_authentication
         put :update, { :id => @user_submission.id,
                        :approve => "true" }
       end
     
       should_redirect_to( "the admin page") { admin_url }
       should set_the_flash.to /Successfully updated/i
     
       should "update member details" do
          assert_equal "foo", @user_submission.item.reload.twitter_account_name
       end
       
       should "mark user_submission as approved" do
         assert @user_submission.reload.approved?
       end
       
       context "and updating fails" do
         setup do
           stub_authentication
           @user_submission.submission_details.class.any_instance.stubs(:approve).returns(false)
           put :update, { :id => @user_submission.id,
                          :approve => "true" }
         end

         should_redirect_to( "the admin page") { admin_url }
         should set_the_flash.to /Problem updating/i

         should "keep user_submission as unapproved" do
           assert !@user_submission.reload.approved?
         end
       end
     end
     
   end
   
   # delete tests
   context "on delete to :destroy a submission" do
     setup do
       @user_submission = Factory(:user_submission)
     end
     
     context "without auth" do
       setup do
         delete :destroy, :id => @user_submission.id
       end
  
       should respond_with 401
     end
  
     context 'with auth' do
       setup do
         stub_authentication
         delete :destroy, :id => @user_submission.id
       end
  
       should "destroy submission" do
         assert_nil UserSubmission.find_by_id(@user_submission.id)
       end
       should_redirect_to ( "the admin page") { admin_url }
       should set_the_flash.to "Successfully destroyed submission"
     end
  
   end
   
end
