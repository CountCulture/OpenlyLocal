require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  context "The Investigation class" do
    setup do
      @investigation = Factory(:investigation)
    end
    
    should validate_presence_of :organisation_name
    should validate_presence_of :standards_body
    
    should have_db_column :uid
    should have_db_column :url
    should have_db_column :organisation_name
    should have_db_column :raw_html
    should have_db_column :standards_body
    should have_db_column :title
    should have_db_column :subjects
    should have_db_column :date_received
    should have_db_column :date_completed
    should have_db_column :description
    should have_db_column :result
    should have_db_column :case_details
    should have_db_column :full_report_url
    
    context "before saving" do
      setup do
        @case_details = "some <font='Helvetica'>stylized text</font> with <a href='councillor22'>relative link</a> and an <a href='http://external.com/dummy'>absolute link</a>."*10
        @investigation.case_details = @case_details
      end
      
      context "and description is blank" do

        should "calculate precis from case_details as description" do
          DocumentUtilities.expects(:precis).with(@case_details)
          @investigation.save!
        end
        
        should "save calculated precis as description" do
          DocumentUtilities.stubs(:precis).with(@case_details).returns('foo bar')
          @investigation.save!
          assert_equal 'foo bar', @investigation.description
        end
      end
      
      context "and description exists" do
        setup do
          @investigation.description = 'some words'
        end

        should "not calculate precis" do
          DocumentUtilities.expects(:precis).never
          @investigation.save!
        end
        
        should "not change description" do
          @investigation.save!
          assert_equal 'some words', @investigation.description
        end
      end
    end
  end
end
