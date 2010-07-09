require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  context "The Investigation class" do
    setup do
      @supplier = Factory(:investigation)
      # @organisation = @investigation.organisation
    end
    
    # should have_many :financial_transactions
    # should belong_to :company
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
    should have_db_column :allegation
    should have_db_column :result
    should have_db_column :case_details
  end
end
