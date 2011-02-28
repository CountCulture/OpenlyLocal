require "test_helper"

class TestAddresseeModel <ActiveRecord::Base
  set_table_name "candidates"
  include AddressUtilities::Base
end

class AddressUtilitiesTest < ActiveSupport::TestCase
  
  context "A class that includes AddressUtilities::Base mixin" do
    subject { @test_model_with_address }
    
    setup do
      @test_model_with_address = TestAddresseeModel.create!
      @address = Factory(:address, :addressee => @test_model_with_address, :street_address => '2 Wilson Road', :locality => 'Sometown')
      @former_address = Factory(:address, :addressee => @test_model_with_address, :street_address => '2 Heath St', :locality => 'Sometown', :former => true)
    end
    
    should_have_one :full_address, :dependent => :destroy
    
    context 'and full_address association' do
      should 'not return former addresses' do
        @address.update_attribute(:former, true)
        assert_nil @test_model_with_address.full_address
      end
      
      should 'be polymorphic as addressee' do
        assert_equal @test_model_with_address, @address.addressee
        assert_equal @address, @test_model_with_address.full_address
      end

    end
    
    should have_many :former_addresses
    
    context 'and former_addresses association' do
      should 'include former addresses' do
        assert @test_model_with_address.former_addresses.include?(@former_address)
      end
      
      should 'not include current addresses' do
        assert !@test_model_with_address.former_addresses.include?(@address)
      end
    end
    
    should "delegate address_in_full to associated address" do
      assert_equal @address.in_full, @test_model_with_address.address_in_full
    end
    
    should "return nil for address_in_full if no associated address" do
      assert_nil TestAddresseeModel.new.address_in_full
    end
    
    should 'alias full_address getter method as address' do
      assert_equal @test_model_with_address.full_address, @test_model_with_address.address
    end
    
    context 'when assigning address' do
      setup do
        @test_model_without_address = TestAddresseeModel.create!
        @unsaved_address = Address.new(:street_address => '1 Acacia Ave', :locality => 'anytown')
      end
      
      context 'in general' do
        context 'and params are an address' do
          setup do
            @test_model_without_address.address = @unsaved_address
          end

          should_create :address
          
          should 'assign address to addressee' do
            assert_equal @unsaved_address, @test_model_without_address.address.reload
          end

          should 'save association' do
            assert_equal @unsaved_address, @test_model_without_address.reload.address
          end
        end

        context 'and params are nil' do
          should 'not raise exception' do
            assert_nothing_raised(Exception) {  @test_model_without_address.address = nil }
          end
        end

        context 'and params are hash' do
          setup do
            @test_model_without_address.address = { :street_address => '1 Acacia Ave', :locality => 'Anytown' }
          end

          should_create :address

          should 'assign address to addressee' do
            assert_kind_of Address, @test_model_without_address.address
          end

          should 'use hash keys, values to set address attributes' do
            assert_equal '1 Acacia Ave', @test_model_without_address.address.street_address
            assert_equal 'Anytown', @test_model_without_address.address.locality
          end

        end
      end
      
      context 'and address already exists' do

        context 'and params are an address' do
          setup do
            @test_model_with_address.address = @unsaved_address
          end
          
          should_create :address
          
          should 'assign new address to addressee' do
            assert_equal @unsaved_address, @test_model_with_address.address
          end

          should 'save new address' do
            assert !@unsaved_address.new_record?
          end

          should 'mark old address as former' do
            assert @address.reload.former?
          end

        end

        context 'and params are nil' do
          should 'not raise exception' do
            assert_nothing_raised(Exception) {  @test_model_with_address.address = nil }
          end
          
          should 'not create a new address' do
            assert_no_difference "Address.count" do
              @test_model_with_address.address = nil
            end
          end
          
          should 'mark old address as former' do
            @test_model_with_address.address = nil
            assert @address.reload.former?
          end
        end

        context 'and params are hash' do
          setup do
            @test_model_with_address.address = { :street_address => '1 Acacia Ave', :locality => 'Anytown' }
          end

          should_create :address

          should 'assign address to addressee' do
            assert_kind_of Address, @test_model_with_address.address
          end

          should 'use hash keys, values to set address attributes' do
            assert_equal '1 Acacia Ave', @test_model_with_address.address.street_address
            assert_equal 'Anytown', @test_model_with_address.address.locality
          end

          should 'mark old address as former' do
            assert @address.reload.former?
          end

        end
      end
    end
  end
 
  context "An instance of a class that includes AddressUtilities::Base mixin" do
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
  
  context "the Parser module" do
    
    context "when parsing" do
      should "parse address from string" do
        original_and_parsed_address = {
          "32 Acacia Avenue, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue, Anytown, AT1 2BT, United Kingdom" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'United Kingdom'},
          "CANUK House, 32 Acacia Avenue, Anytown, AT1 2BT" => {:street_address => 'CANUK House, 32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue\nAnytown\r\nAT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue\n Anytown\r\n AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue,\n Anytown,\r\n AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue, Little Village, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue, Little Village', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue, Anytown" => {:street_address => '32 Acacia Avenue', :postal_code => nil, :locality => 'Anytown'},
          "32, Acacia Avenue, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'}
        }.each do |orig, expected|
          parsed = AddressUtilities::Parser.parse(orig)
          assert_equal expected, parsed, "failed for #{orig}. Parsed address = #{parsed.inspect}"
        end
      end
      
      should "extract country from address with UK tye postcodes" do
        original_and_parsed_address = {
          "32 Acacia Avenue, Anytown, AT1 2BT, United Kingdom" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'United Kingdom'},
          "32 Acacia Avenue, Anytown, AT1 2BT, UNITED KINGDOM" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'United Kingdom'},
          "32 Acacia Avenue, Anytown, AT1 2BT, UK" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'United Kingdom'},
          "32 Acacia Avenue, Anytown, AT1 2BT, U.K." => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'United Kingdom'},
          "32 Acacia Avenue, Anytown, AT1 2BT, Jersey Channel Islands" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Jersey'},
          "32 Acacia Avenue, Anytown, AT1 2BT, Jersey, Channel Islands" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Jersey'},
          "32 Acacia Avenue, Anytown, AT1 2BT, JERSEY CHANNEL ISLANDS" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Jersey'},
          "32 Acacia Avenue, Anytown, AT1 2BT, GUERNSEY CHANNEL ISLANDS" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Guernsey'},
          "32 Acacia Avenue, Anytown, AT1 2BT  IoM" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Isle of Man'},
          "32 Acacia Avenue, Anytown, AT1 2BT, ISLE OF MAN" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown', :country => 'Isle of Man'}
        }.each do |orig, expected|
          parsed = AddressUtilities::Parser.parse(orig)
          assert_equal expected, parsed, "failed for #{orig}. Parsed address = #{parsed.inspect}"
        end
      end
    end
  end
end
