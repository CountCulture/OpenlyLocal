require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  context "The Company class" do
    setup do
      @company = Factory(:company)
      # @supplier = Factory(:supplier, :company => @company)
    end
  
    should have_many :suppliers
    should_validate_presence_of :title
  
    should have_db_column :title
    should have_db_column :company_number
    should have_db_column :url
    should have_db_column :normalised_title

    context "when normalising title" do
      should "normalise title" do
        TitleNormaliser.expects(:normalise_company_title).with('foo bar')
        Company.normalise_title('foo bar')
      end
    end
  end
  
  context "An instance of the Company class" do
    setup do
      @company = Factory(:company)
    end

    context "when saving" do
      should "normalise title" do
        @company.expects(:normalise_title)
        @company.save!
      end

      should "save normalised title" do
        @company.title = "Foo & Baz Ltd."
        @company.save!
        assert_equal "foo and baz limited", @company.reload.normalised_title
      end
    end

    context 'when returning companies_house_url' do
      should 'return nil by default' do
        assert_nil @company.companies_house_url
        @company.company_number = ''
        assert_nil @company.companies_house_url
      end
      
      should "return companies open house url if company_number set" do
        @company.company_number = '012345'
        assert_equal 'http://companiesopen.org/uk/012345/companies_house', @company.companies_house_url
      end
      
      # should "return nil if company_number -1" do
      #   @company.company_number = '-1'
      #   assert_nil @company.companies_house_url
      # end
      
    end

  end
end
