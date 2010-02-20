require 'test_helper'

class UserSubmissionsControllerTest < ActionController::TestCase
  
  # new test
  context "on GET to :new" do
    
    context "in general" do
      setup do
        get :new
      end
      
      should_assign_to(:user_submission) { @user_submission}
      should_respond_with :success
      should_render_template :new
      should_render_with_layout

      should "show title" do
        assert_select 'title', /new twitter/i
      end

      should "show form" do
        assert_select "form#new_user_submission"
      end

      should "show all councils in select box" do
        assert_select "select#user_submission_council_id"
      end
      
      should "show text_field for member name" do
        assert_select "input#user_submission_member_name"
      end
    end
    
    context "with council_id given" do
      
      setup do
        @member = Factory(:member)
        get :new, :council_id => @member.council.id
      end
      
      should_assign_to(:user_submission) { @user_submission}
      should_respond_with :success

      should "associate council with user submission" do
        assert_equal @member.council, assigns(:user_submission).council
      end

      should "select council in select box" do
        assert_select "select#user_submission_council_id" do
          assert_select "option", 2 do #1 for council, 1 for blank
            assert_select "option[value=#{@member.council.id}]"
          end
        end
      end
      
      should "show list of possible members in select box" do
        assert_select "select#user_submission_member_id" do
          assert_select "option", 2 do #1 for member, 1 for blank
            assert_select "option[value=#{@member.id}]"
          end
        end
      end
      
      should "not show text_field for member name" do
        assert_select "input#user_submission_member_name", false
      end
    end
    
    context "with council_id given but no members for council" do
      
      setup do
        @council = Factory(:council)
        get :new, :council_id => @council.id
      end
      
      should_assign_to(:user_submission) { @user_submission}
      should_respond_with :success

      should "associate council with user submission" do
        assert_equal @council, assigns(:user_submission).council
      end

      should "select council in select box" do
        assert_select "select#user_submission_council_id" do
          assert_select "option[value=#{@council.id}]"
        end
      end
      
      should "not_show list of possible members in select box" do
        assert_select "select#user_submission_member_id", false
      end
      
      should "show text_field for member name" do
        assert_select "input#user_submission_member_name"
      end
    end
    
    context "with member_id given" do
      
      setup do
        @member = Factory(:member)
        get :new, :member_id => @member.id
      end
      
      should_assign_to(:user_submission) { @user_submission}
      should_respond_with :success
      should_render_template :new
      should_render_with_layout

      should "associate member with user submission" do
        assert_equal @member, assigns(:user_submission).member
      end

      should "show form" do
        assert_select "form#new_user_submission"
      end

      should "not show all councils in select box" do
        assert_select "select#user_submission_council_id", false
      end
      
      should "show member_details" do
        assert_select ".member_link", @member.full_name
      end
      
      should "include member_id in hidden field" do
        assert_select "input[type='hidden'][value='#{@member.id}']"
      end
    end
  end
  
  # create test
   context "on POST to :create" do
     setup do
       @council = Factory(:council)
       @attributes = Factory.attributes_for(:user_submission, :council => @council)
     end
    
    context "with valid params" do
       setup do
         post :create, :user_submission => @attributes
       end
     
       should_change "UserSubmission.count", :by => 1
       should_assign_to :user_submission
       should_redirect_to( "the page for the council") { council_url(@council) }
       should_set_the_flash_to /Successfully submitted/i
        
     end
     
     context "with member_id but no council" do
        setup do
          @member = Factory(:member, :council => @council)
          post :create, :user_submission => { :twitter_account_name => "foobar", :member_id => @member.id }
        end

        should_change "UserSubmission.count", :by => 1
        should_assign_to :user_submission
        should_redirect_to( "the page for the member's council") { council_url(@council) }
        should_set_the_flash_to /Successfully submitted/i
        
        should "set the council and member for the user_submission" do
          user_submission = UserSubmission.find_by_twitter_account_name("foobar")
          assert_equal @member, user_submission.member
          assert_equal @council, user_submission.council
        end
      end

     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :user_submission => {:twitter_account_name => "foo"}
       end
     
       should_not_change "UserSubmission.count"
       should_assign_to :user_submission
       should_render_template :new
       should_not_set_the_flash
     end
    
   end
   
   # update tests
   context "on PUT to :update without auth" do
     setup do
       @member = Factory(:member)
       @user_submission = Factory(:user_submission, :council => @member.council, :member => @member, :twitter_account_name => "foo")
     end
     
     context "without auth" do
       setup do
         put :update, { :id => @user_submission.id,
                        :user_submission => { :approve => "true"}}
       end

       should_respond_with 401
     end

     context "in general" do
       setup do
         stub_authentication
         put :update, { :id => @user_submission.id,
                        :user_submission => { :approve => "true"}}
       end

       should_redirect_to( "the admin page") { admin_url }
       should_set_the_flash_to /Successfully updated/

       should "update member details" do
         assert_equal "foo", @member.reload.twitter_account_name
       end
     end
     
     context "when no associated member in submission" do
       setup do
         stub_authentication
         @user_submission.update_attribute(:member, nil)
         put :update, { :id => @user_submission.id,
                        :user_submission => { :approve => "true"}}
       end

       should_redirect_to( "the admin page") { admin_url }
       should_set_the_flash_to /Problem updating/

       should "not update member details" do
         assert_nil @member.reload.twitter_account_name
       end
     end
   end
   
end
