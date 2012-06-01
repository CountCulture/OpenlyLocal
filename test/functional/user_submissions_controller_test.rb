require File.expand_path('../../test_helper', __FILE__)

class UserSubmissionsControllerTest < ActionController::TestCase
  
  # new test
  context "on GET to :new" do
    
    context "in general" do
      setup do
        @item = Factory(:council)
        get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'Council', :item_id => @item.id}
      end
      
      should assign_to(:user_submission)
      should respond_with :success
      should render_template :new
      should render_with_layout

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

      should 'form should use post method to create' do
        assert_select 'form#new_user_submission[method=post]'
        assert_select "form#new_user_submission[action*='user_submissions']"
      end
      
      should "show fieldset" do
        assert_select "fieldset#submission_details"
      end
      
      should "show text_fields for submission_details" do
        assert_select "input#user_submission_submission_details_twitter_account_name"
      end
      
      should 'show item as hidden field' do
        assert_select "input#user_submission_item_id[type=hidden][value=#{@item.id}]"
        assert_select "input#user_submission_item_type[type=hidden][value=Council]"
      end
      
      should 'show submission_type as hidden field' do
        assert_select "input#user_submission_submission_type[type=hidden][value=social_networking_details]"
      end
    end
    
    context "when submission_type is supplier details" do
      setup do
        @base_object = Factory(:police_authority)
        @supplier = Factory(:supplier)
        @basic_params = {:user_submission => {:submission_type => 'supplier_details', 
                                              :item_type => 'Supplier', 
                                              :item_id => @supplier.id}}
      end
      
      context "in general" do
        setup do
          get :new, @basic_params
        end

        should assign_to(:user_submission)
        should respond_with :success
        should render_template :new
        should render_with_layout

        should "show possible entity types in radio buttons" do
          assert_select "fieldset#submission_details" do
            # puts css_select('fieldset')
            assert_select 'input#user_submission_submission_details_entity_type_charity'
          end
        end
        
        should 'form should use get method to new' do
          assert_select 'form#new_user_submission[method=get]'
        end
        
      end
      
      context "when entity_type is given" do
        setup do
          @basic_params = {:user_submission => {:submission_type => 'supplier_details', 
                                                :item_type => 'Supplier', 
                                                :item_id => @supplier.id, 
                                                :submission_details => {:entity_type => 'PoliceAuthority'}}}
          @result_1 = GenericEntityMatcher::MatchResult.new(:base_object => @base_object)
        end
        
        should "get matching records" do
          GenericEntityMatcher.expects(:possible_matches).with(:title => @supplier.title, :type => 'PoliceAuthority').returns(:result => [@result_1])
          get :new, @basic_params
        end

        context "in general" do
          setup do
            GenericEntityMatcher.stubs(:possible_matches).returns(:result => [@result_1])
            get :new, @basic_params
          end

          should respond_with :success
          should assign_to(:possible_entities)
          should render_template :new

          should "list possible entities" do
            assert_select 'select#user_submission_submission_details_entity_id option', /#{@base_object.title}/
          end
        end
        
        context "and no possible_matches" do
          setup do
            GenericEntityMatcher.stubs(:possible_matches).returns(:result => [])
          end
          
          context "in general" do
            setup do
              get :new, @basic_params
            end

            should respond_with :success
            should assign_to(:possible_entities) {[]}
            should render_template :new

            should "show no_possible_matches found fieldset for entity_type" do
              assert_select '#no_possible_police_authority_matches'
            end


            should "show generic no_possible_matches fields" do
              assert_select 'input#user_submission_submission_details_url'
            end
          end

          context "when entity_type has dedicated no_possible_matches fields" do
            setup do
              params = {:user_submission => {:submission_type => 'supplier_details', 
                                                    :item_type => 'Supplier', 
                                                    :item_id => @supplier.id, 
                                                    :submission_details => {:entity_type => 'Company'}}}
              get :new, params
            end

            should respond_with :success
            should assign_to(:possible_entities) {[]}
            should render_template :new

            should "show no_possible_matches found fieldset for entity_type" do
              assert_select '#no_possible_company_matches'
            end

            should "show dedicated fields" do
              assert_select 'input#user_submission_submission_details_company_number'
            end
          end

        end
      end
    end
    
    context "when submission_type is social networking details" do
      context "in general" do
        setup do
          @item = Factory(:council)
          get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'Council', :item_id => @item.id}
        end

        should respond_with :success

        should "not show blog_url field" do
          assert_select "input#user_submission_submission_details_blog_url", false
        end
      end
      
      context "when item is Member" do
        setup do
          @item = Factory(:member)
          get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'Member', :item_id => @item.id}
        end

        should respond_with :success

        should "show blog_url field" do
          assert_select "input#user_submission_submission_details_blog_url"
        end
        
        should "show url field" do
          assert_select "input#user_submission_submission_details_url", false
        end
      end
      
      context "when item doesn't have website attribute" do
        setup do
          @item = Factory(:member)
          get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'Member', :item_id => @item.id}
        end

        should "not show website field" do
          assert_select "input#user_submission_submission_details_website", false
        end
        
      end
      
      context "when item has website attribute" do
        setup do
          @item = Factory(:parish_council)
        end

        should "show website field" do
          get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'ParishCouncil', :item_id => @item.id}
          assert_select "input#user_submission_submission_details_website"
        end
        
        should "not show website field when website already set" do
          @item.update_attribute(:website, 'http://foo.com') 
          get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'ParishCouncil', :item_id => @item.id}
          assert_select "input#user_submission_submission_details_website", false
        end
        
      end
      
      # setup do
      #   @item = Factory(:council)
      #   get :new, :user_submission => {:submission_type => 'social_networking_details', :item_type => 'Council', :item_id => @item.id}
      # end
      
      # should assign_to(:user_submission)
      # should render_template :new
      # should render_with_layout
      # 
      # should "set submission_details for user submission" do
      #   assert_kind_of SocialNetworkingDetails, assigns(:user_submission).submission_details
      # end
      # 
      # should "associate given item with user submission" do
      #   assert_equal @item, assigns(:user_submission).item
      # end
    end
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
      should redirect_to( "the page for the council") { council_url(@item) }
      should set_the_flash.to /Successfully submitted/i
       
    end
    
    context "with entity_type" do
      setup do
        @entity = Factory(:police_authority)
        post :create, :user_submission => { :item_id => @item.id, 
                                            :item_type => 'Council', 
                                            :submission_type => 'supplier_details', 
                                            :submission_details => {:entity_type => 'PoliceAuthority', :entity_id => @entity.id}}
      end
    
      should_change("The number of user_submissions", :by => 1) { UserSubmission.count }
      should assign_to :user_submission
      should redirect_to( "the page for the council") { council_url(@item) }
      should set_the_flash.to /Successfully submitted/i
    
    end
    
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
      should render_with_layout
  
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
    
      should redirect_to( "the admin page") { admin_url }
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
          @user_submission.submission_details.class.any_instance.expects(:approve).returns(false)
          put :update, { :id => @user_submission.id,
                         :approve => "true" }
        end
  
        should redirect_to( "the edit page for the user submission") { edit_user_submission_url(@user_submission) }
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
      should redirect_to( "the admin page") { admin_url }
      should set_the_flash.to "Successfully destroyed submission"
    end
  
  end
  
end
