require 'test_helper'

class ParishCouncilsControllerTest < ActionController::TestCase

  should "route resource to show action" do
    assert_routing "/parish_councils/23", {:controller => "parish_councils", :action => "show", :id => "23"} #default route
    assert_routing "/id/parish_councils/23", {:controller => "parish_councils", :action => "show", :id => "23", :redirect_from_resource => true}
  end
  
  should "route council identified by os_id to show action" do
    assert_routing "parish_councils/os_id/1023", {:controller => "parish_councils", :action => "show", :os_id => "1023"}
    assert_routing "parish_councils/os_id/1023.xml", {:controller => "parish_councils", :action => "show", :os_id => "1023", :format => "xml"}
    assert_routing "parish_councils/os_id/1023.json", {:controller => "parish_councils", :action => "show", :os_id => "1023", :format => "json"}
    assert_routing "parish_councils/os_id/1023.rdf", {:controller => "parish_councils", :action => "show", :os_id => "1023", :format => "rdf"}
  end

  # show test
  context "on GET to :show" do
    setup do
      @parish_council = Factory(:parish_council, :council => Factory(:generic_council))
    end
    
    context "in general" do
      setup do
        get :show, :id => @parish_council.id
      end

      should assign_to(:parish_council) { @parish_council}
      should respond_with :success
      should render_template :show
      should render_with_layout

      should "link to parent council" do
        assert_select ".attributes a.council_link", @parish_council.council.title
      end

      should "show parish_council in title" do
        assert_select "title", /#{@parish_council.title}/
      end

      should "show share block" do
        assert_select "#share_block"
      end

      # should "show api block" do
      #   assert_select "#api_info"
      # end
    end
    
    context "when parish_council has supplying relationships" do
      setup do
        @supplier = Factory(:supplier, :payee => @parish_council)
        get :show, :id => @parish_council.id
      end

      should 'list suppliers as organisation' do
        assert_select 'li .supplier_link', /#{@supplier.organisation.title}/
      end
    end

    context "with os_id used to identify parish_council" do
      setup do
        get :show, :os_id => @parish_council.os_id
      end

      should assign_to(:parish_council) { @parish_council}
      should respond_with :success
      should render_template :show
      should render_with_layout
    end
  end  
  
  # context "with xml request" do
  #   setup do
  #     @parish_council.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
  #     get :show, :id => @parish_council.id, :format => "xml"
  #   end
  # 
  #   should assign_to(:parish_council) { @parish_council}
  #   should respond_with :success
  #   should_render_without_layout
  #   should respond_with_content_type 'application/xml'
  #   
  #   should "include attributes in response" do
  #     assert_select "police-force>address"
  #   end
  #   
  #   should "not include npia_id" do
  #     assert_no_match /<npia-id/, @response.body
  #   end
  #   
  #   should "include councils and basic council data in response" do
  #     assert_select "police-force council name", @council.name
  #     assert_select "police-force council id", @council.id.to_s
  #     assert_select "police-force council url", @council.url
  #     assert_select "police-force council openlylocal-url", @council.openlylocal_url
  #   end
  # 
  #   should "not include non-essential council data in response" do
  #     assert_select "police-force council police-force-id", false
  #     assert_select "police-force council wdtk-name", false
  #   end
  # 
  # end
  #  
  # context "with rdf request" do
  #   setup do
  #     @parish_council.update_attributes(:address => "35 Some St, Anytown AN1 2NT", :telephone => "0123 456 789", :wikipedia_url => "http://en.wikipedia.org/wiki/SomeForce")
  #     get :show, :id => @parish_council.id, :format => "rdf"
  #   end
  #  
  #   should assign_to(:parish_council) { @parish_council}
  #   should respond_with :success
  #   should_render_without_layout
  #   should respond_with_content_type 'application/rdf+xml'
  #  
  #   should "show rdf headers" do
  #     assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
  #     assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
  #     assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
  #   end
  # 
  #   should "show alternative representations" do
  #     assert_match /dct:hasFormat rdf:resource.+\/parish_councils\/#{@parish_council.id}.rdf/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/parish_councils\/#{@parish_council.id}\"/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/parish_councils\/#{@parish_council.id}.json/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/parish_councils\/#{@parish_council.id}.xml/m, @response.body
  #   end
  #   
  #   should "show parish_council as primary resource" do
  #     assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/parish_councils\/#{@parish_council.id}/m, @response.body
  #   end
  #   
  #   should "show rdf info for parish_council" do
  #     assert_match /rdf:Description.+rdf:about.+\/id\/parish_councils\/#{@parish_council.id}/, @response.body
  #     assert_match /rdf:Description.+rdfs:label>#{@parish_council.title}/m, @response.body
  #     assert_match /foaf:phone.+#{Regexp.escape(@parish_council.foaf_telephone)}/, @response.body
  #     assert_match /foaf:homepage>#{Regexp.escape(@parish_council.url)}/m, @response.body
  #     assert_match /vCard:Extadd.+#{Regexp.escape(@parish_council.address)}/, @response.body
  #   end
  # 
  #   should "show parish_council is same as dbpedia entry" do
  #     assert_match /owl:sameAs.+rdf:resource.+dbpedia.+SomeForce/, @response.body
  #   end
  #   
  #   should "show associated councils" do
  #     assert_match /openlylocal:isPoliceForceFor.+rdf:resource.+\/id\/councils\/#{@council.id}/, @response.body
  #     assert_match /rdf:Description.+\/id\/councils\/#{@council.id}/, @response.body
  #   end
  # 
  # end
  # 
  # context "with json request" do
  # 
  #    setup do
  #      @parish_council.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
  #      get :show, :id => @parish_council.id, :format => "json"
  #    end
  # 
  #    should respond_with :success
  #    should_render_without_layout
  #    should respond_with_content_type 'application/json'
  #    
  #    should "include attributes in response" do
  #      assert_match /parish_council\":.+address\":/, @response.body
  #    end
  #    
  #    should "include councils and basic council data in response" do
  #      assert_match /parish_council\":.+name.+#{@council.name}/, @response.body
  #      assert_match /parish_council\":.+councils\":.+id\":#{@council.id}/, @response.body
  #      assert_match /parish_council\":.+councils\":.+#{Regexp.escape(@council.url)}/, @response.body
  #    end
  # 
  #    should "not include non-essential council data in response" do
  #      assert_no_match %r(council\":.+parish_council_id), @response.body
  #      assert_no_match %r(council\":.+wdtk_name), @response.body
  #    end
  #   
  #  end
  # 
end
