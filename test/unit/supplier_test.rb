require 'test_helper'

class SupplierTest < ActiveSupport::TestCase
  subject { @supplier }
  
  context "The Supplier class" do
    setup do
      @supplier = Factory(:supplier)
      @organisation = @supplier.organisation
    end
    
    should have_many :financial_transactions
    should_validate_presence_of :organisation_type, :organisation_id
    
    should_have_db_columns :uid, :name, :company_number, :url
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:supplier, :organisation => organisation).organisation
    end
    
    should 'require either name or uid to be present' do
      invalid_supplier = Factory.build(:supplier, :name => nil, :uid => nil)
      assert !invalid_supplier.valid?
      assert_equal 'Either a name or uid is required', invalid_supplier.errors[:base]
      invalid_supplier.name = 'foo'
      assert invalid_supplier.valid?
      invalid_supplier.name = nil
      invalid_supplier.uid = '123'
      assert invalid_supplier.valid?
    end
    
    context 'when validating uniqueness of uid' do
      
      should 'scope to organisation' do
        @supplier.update_attribute(:uid, '123')
        another_supplier = Factory.build(:supplier, :uid => '123') # different org
        assert another_supplier.valid?
        another_supplier.organisation = @organisation
        assert !another_supplier.valid?
      end
      
      should 'allow nil' do
        another_supplier = Factory.build(:supplier, :organisation => @organisation)
        assert another_supplier.valid?
      end
    end
    
    context "when normalising title" do
      setup do
        @original_title_and_normalised_title = {
          "Foo Bar & Baz" => "foo bar and baz",
          "Foo Bar & Baz Ltd" => "foo bar and baz limited",
          "Foo Bar & Baz Ltd." => "foo bar and baz limited",
          "Foo Bar & Baz PLC" => "foo bar and baz plc",
          "Foo Bar & Baz Public Limited Company" => "foo bar and baz plc",
          "Foo Bar & Baz (South) Limited" => "foo bar and baz (south) limited",
          "Foo Bar & Baz (South & NORTH) Limited" => "foo bar and baz (south and north) limited",
          "Foo Bar & Baz Ltd t/a bar foo" => "foo bar and baz limited",
          "Foo Bar & Baz Ltd T/A bar foo" => "foo bar and baz limited"
        }
      end
      
      should "normalise title" do
        @original_title_and_normalised_title.each do |orig_title, normalised_title|
          assert_equal( normalised_title, Supplier.normalise_title(orig_title), "failed for #{orig_title}")
        end
      end
    end
  end
  
  context "An instance of the Supplier class" do
    setup do
      @supplier = Factory(:supplier)
    end

    should "alias name as title" do
      assert_equal @supplier.name, @supplier.title
    end
    
    context 'when returning companies_house_url' do
      should 'return nil by default' do
        assert_nil @supplier.companies_house_url
        @supplier.company_number = ''
        assert_nil @supplier.companies_house_url
      end
      
      should "return companies open house url if company_number set" do
        @supplier.company_number = '012345'
        assert_equal 'http://companiesopen.org/uk/012345/companies_house', @supplier.companies_house_url
      end
      
      should "return nil if company_number -1" do
        @supplier.company_number = '-1'
        assert_nil @supplier.companies_house_url
      end
      
    end

    context 'when returning company_number' do
      should 'return nil if blank?' do
        assert_nil @supplier.company_number
        @supplier.company_number = ''
        assert_nil @supplier.company_number
      end
      
      should "return company_number if set" do
        @supplier.company_number = '012345'
        assert_equal '012345', @supplier.company_number
      end
      
      should "return nil if company_number -1" do
        @supplier.company_number = '-1'
        assert_nil @supplier.company_number
      end
      
    end

  end
end
