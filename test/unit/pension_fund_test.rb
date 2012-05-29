require File.expand_path('../../test_helper', __FILE__)

class PensionFundTest < ActiveSupport::TestCase
  subject { @pension_fund }
  
  context "The PensionFund class" do
    setup do
      @pension_fund = Factory(:pension_fund)
    end

    [:telephone, :fax, :email, :address, :wdtk_name, :wdtk_id].each do |column|
      should have_db_column column
    end

    should have_many :councils 
    should validate_presence_of :name
    should validate_uniqueness_of :name
    
    should "mixin SpendingStat::Base module" do
      assert PensionFund.new.respond_to?(:spending_stat)
    end

    should "mixin SpendingStatUtilities::Payee module" do
      assert PensionFund.new.respond_to?(:supplying_relationships)
    end
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
    
    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/pension_funds/#{@pension_fund.id}", @pension_fund.resource_uri
    end
    
  end
end
