require File.expand_path('../../test_helper', __FILE__)

class UserSubmissionTest < ActiveSupport::TestCase
  subject { @user_submission }

  context "The UserSubmission class" do
    setup do
      @user_submission = Factory(:user_submission)
      @submission_details = {:twitter_account_name => 'bar'}
    end
    
    should belong_to :item
    should validate_presence_of :item_id
    should validate_presence_of :item_type
    should validate_presence_of :submission_details
    should have_db_column :submission_details
    should have_db_column :ip_address
    should have_db_column :notes
    should_not allow_mass_assignment_of :approved
    
    should 'only be valid if submission_details are valid' do
      stub_valid_submission_details = stub_everything(:valid? => true)
      stub_invalid_submission_details = stub_everything
      submission = Factory.build(:user_submission)
      submission.submission_details.expects(:valid?).returns(true)
      assert submission.valid?
      submission.submission_details.expects(:valid?).returns(false)
      assert !submission.valid?
      # p '******************', s.valid?, s.errors
      # assert Factory.build(:user_submission, :submission_details => stub_valid_submission_details).valid?
      # assert !Factory.build(:user_submission, :submission_details => stub_invalid_submission_details).valid?
    end
    
    # should "require either member_name or member_id" do
    #   council = Factory(:another_council)
    #   assert !Factory.build(:user_submission, :member_id => nil, :member_name => nil, :council => council).valid?
    #   assert !Factory.build(:user_submission, :member_id => nil, :member_name => "", :council => council).valid?
    #   assert Factory.build(:user_submission, :member_id => 42, :member_name => nil, :council => council).valid?
    #   assert Factory.build(:user_submission, :member_id => nil, :member_name => "Fred", :council => council).valid?
    # end
    # 
    # should "give nice error meesage if both member_name and member_id blank" do
    #   submission = UserSubmission.new
    #   submission.save
    #   assert_equal "Member info is missing", submission.errors[:base]
    # end
    # 
    # context "when setting twitter_account_name" do
    #   should "set as give name by default" do
    #     assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "FooBar").twitter_account_name
    #   end
    #   
    #   should "strip out '@' sign if given" do
    #     assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "@FooBar").twitter_account_name
    #   end
    # end
    
    should 'serialize submission_details' do
      assert_kind_of UserSubmissionDetails, Factory(:user_submission).reload.submission_details
    end
    
        
    context 'when returning unapproved submissions' do
      setup do
        @approved_user_submission = Factory(:user_submission, :item => Factory(:another_council))
        @approved_user_submission.update_attribute(:approved, true)
      end
      
      should 'return unapproved entries' do
        assert UserSubmission.unapproved.include?(@user_submission)
      end
      
      should 'not return approved entries' do
        assert !UserSubmission.unapproved.include?(@approved_user_submission)
      end
    end
  end
  
  context "An instance of the UserSubmission class" do
    setup do
      @user_submission = Factory(:user_submission)
      @submission_details = {:twitter_account_name => 'bar'}
    end
    
    context "when returning title" do
      should "include human version of submission type" do
        assert_match /#{@user_submission.submission_type.humanize}/, @user_submission.title
      end
      
      should "include item title" do
        assert_match /#{@user_submission.item.title}/, @user_submission.title
      end
    end

    context "when setting submission details" do
      context "and submission_type is set" do
        setup do
          @submission = UserSubmission.new(:submission_type => 'social_networking_details')
          @submission.submission_details = @submission_details
        end

        should "use details as attributes for new instance of type specified in submission_type" do
          assert_kind_of SocialNetworkingDetails, @submission.submission_details
          assert_equal 'bar', @submission.submission_details.twitter_account_name
        end

      end

      context "and submission_type is nil" do
        should "save details as hash" do
          submission = UserSubmission.new
          submission.submission_details = @submission_details
          assert_equal @submission_details, submission.submission_details
        end
      end

      context "and submission_details are being set to type of UserSubmissionDetails" do
        should "set submission_details to given UserSubmissionDetails" do
          submission = UserSubmission.new
          supp_details = SupplierDetails.new
          submission.submission_details = supp_details
          assert_equal supp_details, submission.submission_details
        end
      end

      context "and submission_details are already set" do
        should "set submission_details to new values" do
          @user_submission.submission_details = {:twitter_account_name => 'bar'}
          assert_equal 'bar', @user_submission.submission_details.twitter_account_name
        end
      end

      context "and submission_details are nil" do
        should "not raise exception" do
          submission = UserSubmission.new
          assert_nothing_raised(Exception) { submission.submission_details = nil }
        end

        should "set existing value to nil" do
          @user_submission.submission_details = nil
          assert_nil @user_submission.submission_details
        end
      end
    end

    context "when setting submission_type" do
      setup do
        @submission = UserSubmission.new
      end

      should "set submission_type instance variable" do
        @submission.submission_type = 'social_networking_details'
        assert_equal 'social_networking_details', @submission.instance_variable_get(:@submission_type)
      end

      context "and submission_details are nil" do

        should "set submission_details to new instance of type specified in submission_type" do
          @submission.submission_type = 'social_networking_details'
          assert_kind_of SocialNetworkingDetails, @submission.submission_details
          assert @submission.submission_details.attributes.all?{ |k,v|  v.blank? }
        end
      end

      context "and submission_details are hash" do
        setup do
          @submission.submission_details = @submission_details
        end

        should "convert submission_detail hash to new instance of type using hash for attributes" do
          @submission.submission_type = 'social_networking_details'
          assert_kind_of SocialNetworkingDetails, @submission.submission_details
          assert_equal 'bar', @submission.submission_details.twitter_account_name
        end

      end
    end

    context "when returning submission_type" do
      setup do
        @submission = UserSubmission.new
      end

      context "and submission_type instance_variable is set" do
        setup do
          @submission.instance_variable_set(:@submission_type, 'bar')
        end

        should "return instance_variable" do
          assert_equal 'bar', @submission.submission_type
        end
      end

      context "and submission_type instance_variable is not set" do
        setup do
          @submission.submission_details = SupplierDetails.new
        end

        should "return submission_type from submission_details" do
          assert_equal 'supplier_details', @submission.submission_type
        end

        should "save submission_type in instance variable" do
          @submission.submission_type # triggers setting of instance variable
          assert_equal 'supplier_details', @submission.instance_variable_get(:@submission_type)
        end

        context "and submission_details are not set" do
          setup do
            @submission.submission_details = nil
          end

          should "return nil" do
            assert_nil @submission.submission_type
          end
        end
      end

    end

    context "when updating_attributes" do
      should 'update attributes' do
        @user_submission.update_attributes({"submission_details"=>{"twitter_account_name"=>"bar", "blog_url"=>"http:foo.com/blog"}, "submission_type"=>"social_networking_details"})
        assert_equal 'bar', @user_submission.reload.submission_details.twitter_account_name
        assert_equal 'http:foo.com/blog', @user_submission.submission_details.blog_url
      end
    end

    context "when approving" do
      should 'approve association user_submission_details object passing itself as parameter' do
        submission_details = @user_submission.submission_details
        submission_details.expects(:approve).with(@user_submission)
        @user_submission.approve
      end

      context "and user_submission_details returns false" do
        setup do
          submission_details = @user_submission.submission_details
          submission_details.stubs(:approve).returns(false)
        end

        should "not mark user_submission as approved" do
          @user_submission.approve
          assert !@user_submission.approved?
        end

        should "return false" do
          assert !@user_submission.approve
        end

      end

      context "and user_submission_details returns true" do
        setup do
          submission_details = @user_submission.submission_details
          submission_details.stubs(:approve).returns(true)
        end

        should "mark user_submission as approved" do
          @user_submission.approve
          assert @user_submission.approved?
        end

        should "return true" do
          assert @user_submission.approve
        end
      end
    #   context "and member set" do
    #     setup do
    #       @member = Factory(:member, :council => @user_submission.council)
    #       @user_submission.update_attribute(:member, @member)
    #     end
    #     
    #     should "should update member from user_submission" do
    #       @member.expects(:update_from_user_submission).with(@user_submission)
    #       @user_submission.approve
    #     end
    #     
    #     should "update submission as approved" do
    #       @user_submission.approve
    #       assert @user_submission.reload.approved?
    #     end
    #     
    #     should 'tweet about list addition when twitter_account is created' do
    #       dummy_tweeter = Tweeter.new('foo')
    #       Tweeter.stubs(:new).with(kind_of(Hash)).returns(dummy_tweeter)
    #       
    #       @user_submission.update_attribute(:twitter_account_name, 'foo')
    #       Tweeter.expects(:new).with(regexp_matches(/has been added to @OpenlyLocal #ukcouncillors/), anything).returns(dummy_tweeter)
    #       @user_submission.approve
    #     end
    #     
    #     should 'not tweet about list addition when no twitter_account' do
    #       Tweeter.expects(:new).never
    #       @user_submission.approve
    #     end
    #   end
    #   
    #   context "and member not set" do
    #     should "add errors to user submission" do
    #       @user_submission.approve
    #       assert_match /Can\'t approve/, @user_submission.errors[:member_id]
    #     end
    #     
    #     should "should update submission as approved" do
    #       @user_submission.approve
    #       assert !@user_submission.approved?
    #     end
    #     
    #     should 'not tweet about list addition' do
    #       Tweeter.expects(:new).never
    #       @user_submission.approve
    #     end
    #   end

    end
  end
    
end
