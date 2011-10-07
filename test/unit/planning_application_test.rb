require 'test_helper'

class PlanningApplicationTest < ActiveSupport::TestCase
  context "the PlanningApplication class" do
    should validate_presence_of :council_id
    should validate_presence_of :uid
    should have_db_column :council_id
    should have_db_column :applicant_name
    should have_db_column :applicant_address
    should have_db_column :address
    should have_db_column :postcode
    should have_db_column :description
    should have_db_column :url
    should have_db_column :info_tinyurl
    should have_db_column :comment_url
    should have_db_column :comment_tinyurl
    should have_db_column :uid
    should have_db_column :retrieved_at
    should have_db_column :date_received
    should have_db_column :on_notice_from
    should have_db_column :on_notice_to
    should have_db_column :map_url

    should belong_to :council

    should "serialize other attributes" do
      assert_equal({:foo => 'bar'}, Factory(:planning_application, :other_attributes => {:foo => 'bar'}).reload.other_attributes)
    end
    
    context "stale named scope" do
      setup do
        @no_details_application = Factory(:planning_application) #retrieved_at is nil
        @stale_application = Factory(:planning_application, :retrieved_at => 8.days.ago) 
        @fresh_application = Factory(:planning_application, :retrieved_at => 6.days.ago)
        @stale_applications = PlanningApplication.stale
      end

      should "include applications where retrieved_at is nil" do
        assert @stale_applications.include?(@no_details_application)
      end
      
      should "include applications where retrieved at is more than a week ago" do
        assert @stale_applications.include?(@stale_application)
      end
      
      should "not include fresh applications" do
        assert !@stale_applications.include?(@fresh_application)
      end
    end
  end

  
  context "an instance of the PlanningApplication class" do
    context "when returning title" do
      should "use uid reference" do
        assert_equal "Planning Application AB123/456", PlanningApplication.new(:uid => 'AB123/456').title
      end
      
      should "use address if given" do
        assert_match /32 Acacia Avenue/, PlanningApplication.new(:address => '32 Acacia Avenue, Footown FOO1 3BAR').title
      end
      
      should "use council reference and address if given" do
        application =  PlanningApplication.new(:uid => 'AB123/456', :address => '32 Acacia Avenue, Footown FOO1 3BAR')
        assert_match /32 Acacia Avenue/, application.title
        assert_match /AB123\/456/, application.title
      end
    end
    
    should "alias uid attribute as council_reference" do
      pa = Factory(:planning_application)
      assert_equal pa.uid, pa.council_reference
      pa.council_reference = 'FOO1234'
      assert_equal 'FOO1234', pa.uid
    end
  end
  
end
