require File.expand_path('../../test_helper', __FILE__)

class ChildSubmissionDetails < UserSubmissionDetails
  attr_accessor :dummy, :another_dummy
  
  def foo
  end
end

class UserSubmissionDetailsTest < ActiveSupport::TestCase
  
  context "A UserSubmissionDetails instance" do
    setup do
      @user_submission_details = UserSubmissionDetails.new
    end
    
    should 'have attribute_names method' do
      assert @user_submission_details.respond_to?(:attribute_names)
    end
    
    should 'have attributes method' do
      assert @user_submission_details.respond_to?(:attributes)
    end
    
    should 'have attributes method' do
      assert @user_submission_details.respond_to?(:attributes)
    end
    
    should 'have valid? method' do
      assert @user_submission_details.respond_to?(:valid?)
    end

    should 'have entity_type accessor' do
      assert @user_submission_details.respond_to?(:entity_type)
      assert @user_submission_details.respond_to?(:entity_type=)
    end
    
    should 'have entity_id accessor' do
      assert @user_submission_details.respond_to?(:entity_id)
      assert @user_submission_details.respond_to?(:entity_id=)
    end
    
    context "when returning entity" do
      setup do
        @obj = Factory(:generic_council)
      end
      
      should "return instantiated entity if entity_type and entity_id" do
        assert_equal @obj, UserSubmissionDetails.new(:entity_type => @obj.class.to_s, :entity_id => @obj.id).entity
      end
      
      should "return nil if either entity_type or entity_id or both missing" do
        assert_nil UserSubmissionDetails.new(:entity_type => @obj.class.to_s, :entity_id => nil).entity
        assert_nil UserSubmissionDetails.new(:entity_type => nil, :entity_id => @obj.id).entity
        assert_nil UserSubmissionDetails.new(:entity_type => nil, :entity_id => nil).entity
        assert_nil UserSubmissionDetails.new.entity
      end
      
      should "return nil if no such entity" do
        assert_nil UserSubmissionDetails.new(:entity_type => @obj.class.to_s, :entity_id => 99999).entity
      end
    end
  end
  
  context "An instance of a class that inherits from UserSubmissionDetail" do
    setup do
      @child_submission_details = ChildSubmissionDetails.new(:dummy => 'bar', :another_dummy => 'baz')
    end
    
    should 'assign attributes to instance variables' do
      assert_equal 'bar', @child_submission_details.dummy
      assert_equal 'baz', @child_submission_details.another_dummy
    end
    
    should 'return accessors as attribute_names' do
      assert_equal ['another_dummy', 'dummy', 'entity_id', 'entity_type'], @child_submission_details.attribute_names.sort
    end
    
    should 'not include other methods as attribute_names' do
      assert !@child_submission_details.attribute_names.include?('foo')
    end
    
    should 'returns attribute values keyed to symbolized version of attribute names as attributes' do
      assert_equal( {:dummy => 'bar', :another_dummy => 'baz', :entity_type=>nil, :entity_id=>nil}, @child_submission_details.attributes)
    end
        
    should 'have stub approve method' do
      assert @child_submission_details.respond_to?(:approve)
    end
        
    context "when returning whether valid?" do

      should "by default be false if all attributes blank" do
        assert_equal false, ChildSubmissionDetails.new(:dummy => '').valid?
      end
      
      should "by default not be false if any attribute not blank" do
        assert_equal true, ChildSubmissionDetails.new(:another_dummy => 'foo').valid?
      end
    end
    
  end
  
end