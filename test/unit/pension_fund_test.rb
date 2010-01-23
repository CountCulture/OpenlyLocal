require 'test_helper'

class PensionFundTest < ActiveSupport::TestCase
  subject { @pension_fund }
  
  context "The PensionFund class" do
    setup do
      @pension_fund = Factory(:pension_fund)
    end
    
    should_have_many :councils 
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    
    should_have_db_column :telephone
    should_have_db_column :fax
    should_have_db_column :email
    should_have_db_column :address
    should_have_db_column :wdtk_name
  end
  
  context "A PensionFund instance" do
    setup do
      @pension_fund = Factory(:pension_fund)
    end
    
    should "alias name as title" do
      assert_equal @pension_fund.name, @pension_fund.title
    end

    should "use title in to_param method" do
      @pension_fund.name = "some title-with/stuff"
      assert_equal "#{@pension_fund.id}-some-title-with-stuff", @pension_fund.to_param
    end
  end
end
