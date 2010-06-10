require 'test_helper'

class SupplierTest < ActiveSupport::TestCase
  subject { @supplier }
  
  context "The Supplier class" do
    setup do
      @supplier = Factory(:supplier)
    end
    
    should_validate_presence_of :organisation_type, :organisation_id
    
    should_have_db_columns :uid, :name, :company_number
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:supplier, :organisation => organisation).organisation
    end
    
    # context "with active named scope" do
    #   setup do
    #     @inactive_police_officer = Factory(:inactive_police_officer)
    #   end
    # end
  end
end
