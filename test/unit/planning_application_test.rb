require 'test_helper'

class PlanningApplicationTest < ActiveSupport::TestCase

  should validate_presence_of :council_id
  should have_db_column :council_id
  should have_db_column :applicant_name
  should have_db_column :applicant_address
  should have_db_column :address
  should have_db_column :postcode
  should have_db_column :description
  should have_db_column :info_url
  should have_db_column :info_tinyurl
  should have_db_column :comment_url
  should have_db_column :comment_tinyurl
  should have_db_column :council_reference
  should have_db_column :date_scraped
  should have_db_column :date_received
  should have_db_column :map_url

  should belong_to :council
  
  context "an instance of the PlanningApplication class" do
    context "when returning title" do
      should "use council reference" do
        assert_equal "Planning Application AB123/456", PlanningApplication.new(:council_reference => 'AB123/456').title
      end
      
      should "use address if given" do
        assert_match /32 Acacia Avenue/, PlanningApplication.new(:address => '32 Acacia Avenue, Footown FOO1 3BAR').title
      end
      
      should "use council reference and address if given" do
        application =  PlanningApplication.new(:council_reference => 'AB123/456', :address => '32 Acacia Avenue, Footown FOO1 3BAR')
        assert_match /32 Acacia Avenue/, application.title
        assert_match /AB123\/456/, application.title
      end
    end
    
  end
end
