require 'test_helper'

class SupplierDetailsTest < Test::Unit::TestCase
  
  context "A SupplierDetails instance" do
    setup do
      @supplier_details = SupplierDetails.new
    end
    
    should 'have url accessor' do
      assert @supplier_details.respond_to?(:url)
      assert @supplier_details.respond_to?(:url=)
    end
    
    should 'have company_number accessor' do
      assert @supplier_details.respond_to?(:company_number)
      assert @supplier_details.respond_to?(:company_number=)
    end
    
  end
end