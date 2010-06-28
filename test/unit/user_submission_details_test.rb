require 'test_helper'

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
    
    should 'have valid? method' do
      assert @user_submission_details.respond_to?(:valid?)
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
      assert_equal ['another_dummy', 'dummy'], @child_submission_details.attribute_names.sort
    end
    
    should 'not include other methods as attribute_names' do
      assert !@child_submission_details.attribute_names.include?('foo')
    end
    
    should 'returns attribute values keyed to attribute names as attributes' do
      assert_equal( {'dummy' => 'bar', 'another_dummy' => 'baz'}, @child_submission_details.attributes)
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