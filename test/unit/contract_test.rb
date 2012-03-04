require 'test_helper'

class ContractTest < ActiveSupport::TestCase
  subject { @contract }
  
  context "The Contract class" do
    setup do
      @contract = Factory(:contract)
    end
    
    should_validate_presence_of :organisation_type, :organisation_id
    
    should have_db_column  :title
    should have_db_column  :description
    should have_db_column  :uid
    should have_db_column  :url
    should have_db_column  :start_date
    should have_db_column  :end_date
    should have_db_column  :duration
    should have_db_column  :total_value
    should have_db_column  :annual_value
    should have_db_column  :supplier_name
    should have_db_column  :supplier_uid
    should have_db_column  :department_responsible
    should have_db_column  :person_responsible
    should have_db_column  :email
    should have_db_column  :telephone
    should have_db_column  :source_url
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:contract, :organisation => organisation).organisation
    end
    
    # context "with active named scope" do
    #   setup do
    #     @inactive_police_officer = Factory(:inactive_police_officer)
    #   end
    # end
  end
end
