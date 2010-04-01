require 'test_helper'

class AreasControllerTest < ActionController::TestCase
  
  # routing tests
  should "route ward identified by postcode to show action" do
    assert_routing "areas/postcodes/ab123n", {:controller => "areas", :action => "show", :postcode => "ab123n"}
    assert_routing "areas/postcodes/ab123n.xml", {:controller => "areas", :action => "show", :postcode => "ab123n", :format => "xml"}
    assert_routing "areas/postcodes/ab123n.json", {:controller => "areas", :action => "show", :postcode => "ab123n", :format => "json"}
    assert_routing "areas/postcodes/ab123n.rdf", {:controller => "areas", :action => "show", :postcode => "ab123n", :format => "rdf"}
  end


  # show test
  context "on GET to :show" do
    setup do
     @county = Factory(:council, :name => "Big County")
     @council_1 = Factory(:council, :parent_authority => @county)
     @council_2 = Factory(:council, :name => "2nd council", :parent_authority => @county)
     @council_3 = Factory(:council, :name => "3rd council") # no parent auth
     @council_ward = Factory(:ward, :council => @council_1)
     @county_ward_1 = Factory(:ward, :council => @county, :name => "County Ward 1")
     @county_ward_2 = Factory(:ward, :council => @county, :name => "County Ward 2")
     @member_1 = Factory(:member, :ward => @council_ward, :council => @council_1)
     @county_member = Factory(:member, :ward => @county_ward, :council => @county)
     @another_county_member = Factory(:member, :ward => @county_ward, :council => @county)
     
     @postcode = Factory(:postcode, :code => "ZA133SL", :ward => @council_ward, :council => @council_1, :county => @county )
     @another_postcode = Factory(:postcode)
    end
  
    context "with given postcode" do
      setup do
        get :show, :postcode => 'za13 3sl'
      end
  
      should_assign_to(:postcode) { @postcode }
      should_assign_to(:council) { @council_1 }
      should_assign_to(:county) { @county }
      should_assign_to(:ward) { @ward }
      should_assign_to(:members) { [@member_1] }

      should_respond_with :success
      should_render_template :show
      should_respond_with_content_type 'text/html'
      
      should 'show nice postcode in title' do
        assert_select 'title', /ZA13 3SL/
      end
      
      should 'show council' do
        assert_select 'a.council_link', /#{@council_1.title}/
      end
      
    end
  end
end
