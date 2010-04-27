require 'test_helper'

class ContractTest < ActiveSupport::TestCase
  subject { @contract }
  
  context "The Contract class" do
    setup do
      @contract = Factory(:contract)
    end
    
    should_validate_presence_of :organisation_type, :organisation_id
    
    should_have_db_columns :title, :description, :uid, :url, :start_date, :end_date, :duration, :total_value, :annual_value, :supplier_name, :supplier_uid, :department_responsible, :person_responsible, :email, :telephone, :source_url
    
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
