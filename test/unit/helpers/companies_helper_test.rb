require File.expand_path('../../../test_helper', __FILE__)

class CompaniesHelperTest < ActionView::TestCase
  include ApplicationHelper
  
  context "payer_breakdown_table helper method" do
    setup do
      @company = Factory(:company)
      @council_1 = Factory(:generic_council)
      @council_2 = Factory(:generic_council)
      @supplier_1 = Factory(:supplier, :payee => @company, :organisation => @council_1)
      @supplier_2 = Factory(:supplier, :payee => @company, :organisation => @council_2)
      @supplier_3 = Factory(:supplier, :payee => @company, :organisation => @council_2)
      # datapoint_1 = stub_everything(:value => 53, :short_title => '0-17')
      # datapoint_2 = stub_everything(:value => 42.3, :short_title => '18-25')
      # datapoint_3 = stub_everything(:value => 61, :short_title => '26-35')
      @payer_breakdown = [@supplier_1, @supplier_2, @supplier_3]
      @payer_breakdown_data = [ [@council_1, {:elements => [ @supplier_1 ], :subtotal => [:@council_1, 123, 45]}],
                                [@council_2, {:elements => [ @supplier_2, @supplier_3 ], :subtotal => [:@council_2, 234, 56]}]]
      
      @parsed_table = Hpricot(payer_breakdown_table(@payer_breakdown_data))
    end

    should "should return nil if no supplying_relationships" do
      assert_nil payer_breakdown_table([])
    end

    should "should return table" do
      assert @parsed_table.at('table#payer_breakdown.statistics')
    end

    should "give have caption" do
      assert_equal "Payer breakdown", @parsed_table.at('table caption').inner_text
    end
    
    should "use appropriate headings" do
      assert @parsed_table.at('table th[text()="Payed By"]')
      assert @parsed_table.at('table th[text()="Total Spend"]')
      assert @parsed_table.at('table th[text()="Average Monthly Spend"]')
    end
    
    should "have element row for each supplying_relationship" do
      assert_equal 3, @parsed_table.search('table tr.element[td]').size
    end
    
    should "have subtotal row for each payer organisation" do
      assert_equal 2, @parsed_table.search('table tr.subtotal[td]').size
    end
    
    should "not show link to more info" do
      assert !@parsed_table.at('a.more_info')
    end
    
    should "use appropriate classes on table headers and rows" do
      assert_equal ['description','value', 'value'], @parsed_table.search('th').collect{|th| th[:class]}
    end
  end
  
end
