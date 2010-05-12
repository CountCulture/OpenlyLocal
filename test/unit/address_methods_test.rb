require "test_helper"

class TestAddresseeModel <ActiveRecord::Base
  set_table_name "candidates"
  include AddressMethods
end

class AddressMethodsTest < ActiveSupport::TestCase
  
  context "A class that includes AddressMethods mixin" do
    subject { @test_model_with_address }
    
    setup do
      @test_model_with_address = TestAddresseeModel.create!
      @address = Factory(:address, :addressee => @test_model_with_address)
    end
    
    should_have_one :address, :dependent => :destroy
        
    should "accept nested attributes for address" do
      assert @test_model_with_address.class.instance_methods.include?("address_attributes=")
    end
    
    should "delegate address_in_full to associated address" do
      assert_equal @address.in_full, @test_model_with_address.address_in_full
    end
    
    should "return nil for address_in_full if no associated address" do
      assert_nil TestAddresseeModel.new.address_in_full
    end
        
  end
 
  context "An instance of a class that includes AddressMethods mixin" do
    setup do
      @test_model = TestAddresseeModel.create!
    end
    
    context "when calling address_in_full setter method" do
      
      context "and instance has no associated address" do
        should "create Address" do
          assert_difference "Address.count", 1 do
            @test_model.address_in_full = "32 Acacia Avenue, Anytown, AT1 2BT"
          end
        end

        should "do nothing if name is blank" do
          assert_no_difference "Address.count" do
            @test_model.address_in_full = ""
            @test_model.address_in_full = nil
          end
        end

        should "associate address with instance" do
          @test_model.address_in_full = "32 Acacia Avenue, Anytown, SW19 4AL"
          assert_equal @test_model.address, Address.find_by_postal_code("SW19 4AL")
        end
      end
      
      context "and instance already has associated address" do
        setup do
          @test_model.address_in_full = "32 Acacia Avenue, Anytown, AT1 2BT"
          @address = @test_model.address
        end
        
        should "not create new Address" do
          assert_no_difference "Address.count"do
            @test_model.address_in_full = "32 Different Road, Anothertown, AT5 5AN"
          end
        end
        
        should "update existing address with new name" do
          @test_model.address_in_full = "32 Different Road, Anothertown, AT5 5AN"
          assert_equal @test_model.reload.address, Address.find_by_postal_code("AT5 5AN")
        end
        
        should "destroy address if name is empty string" do
          assert_difference "Address.count", -1 do
            @test_model.address_in_full = ""
          end
          assert_nil Address.find_by_id(@address.id)
        end
        
        should "destroy address if name is nil" do
          assert_difference "Address.count", -1 do
            @test_model.address_in_full = nil
          end
          assert_nil Address.find_by_id(@address.id)
        end
      end
            
    end
    
  end
  
end
