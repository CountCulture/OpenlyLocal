require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase

  def setup
    @investigation = Factory(:investigation)
    # @police_force = @investigation.police_force
    # @council = Factory(:council, :police_force_id => @police_force.id)
  end
  
  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end
  
      should assign_to(:investigations) { Investigation.all }
      should respond_with :success
      should render_template :index
      should "list investigations" do
        assert_select "li a", /#{@investigation.title}/
      end
  
      should "show share block" do
        assert_select "#share_block"
      end
  
      should "show api block" do
        assert_select "#api_info"
      end
  
      should 'show title' do
        assert_select "title", /investigations/i
      end
    end
  
    context "with xml request" do
      setup do
        # @investigation.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
        get :index, :format => "xml"
      end
  
      should assign_to(:investigations) { Investigation.find(:all) }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
    end
  
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should assign_to(:investigations) { Investigation.find(:all) }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'
    end
  
  end  
  
  # show test
  context "on GET to :show" do
    setup do
      get :show, :id => @investigation.id
    end
  
    should assign_to(:investigation) { @investigation}
    should respond_with :success
    should render_template :show
    should render_with_layout
  
    # should "list all associated councils" do
    #   assert_select "#councils li", @investigation.councils.size do
    #     assert_select "a", @council.title
    #   end
    # end
    #   
    # should "link to associated police_force" do
    #   assert_select ".attributes a", @police_force.name
    # end
    #   
    should "show investigation in title" do
      assert_select "title", /#{@investigation.title}/
    end
      
    should "show share block" do
      assert_select "#share_block"
    end
      
    should "show api block" do
      assert_select "#api_info"
    end
  end  
  
  context "with xml request" do
    setup do
      # @investigation.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
      get :show, :id => @investigation.id, :format => "xml"
    end
  
    should assign_to(:investigation) { @investigation}
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/xml'
  
    # should "include attributes in response" do
    #   assert_select "police-authority>address"
    # end
    #   
    # should "include councils and basic council data in response" do
    #   assert_select "police-authority council name", @council.name
    #   assert_select "police-authority council id", @council.id.to_s
    #   assert_select "police-authority council url", @council.url
    #   assert_select "police-authority council openlylocal-url", @council.openlylocal_url
    # end
    #   
    # should "not include non-essential council data in response" do
    #   assert_select "police-authority council police-authority-id", false
    #   assert_select "police-authority council wdtk-name", false
    # end
   #  
   # end
   
  # context "with rdf request" do
  #   setup do
  #     @investigation.update_attributes(:address => "35 Some St, Anytown AN1 2NT", :telephone => "0123 456 789", :wikipedia_url => "http://en.wikipedia.org/wiki/SomeForce")
  #     get :show, :id => @investigation.id, :format => "rdf"
  #   end
  # 
  #   should assign_to(:investigation) { @investigation}
  #   should respond_with :success
  #   should_not render_with_layout
  #   should respond_with_content_type 'application/rdf+xml'
  # 
  #   should "show rdf headers" do
  #     assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
  #     assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
  #     assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
  #   end
  # 
  #   should "show alternative representations" do
  #     assert_match /dct:hasFormat rdf:resource.+\/investigations\/#{@investigation.id}.rdf/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/investigations\/#{@investigation.id}\"/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/investigations\/#{@investigation.id}.json/m, @response.body
  #     assert_match /dct:hasFormat rdf:resource.+\/investigations\/#{@investigation.id}.xml/m, @response.body
  #   end
  # 
  #   should "show investigation as primary resource" do
  #     assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/investigations\/#{@investigation.id}/m, @response.body
  #   end
  # 
  #   should "show rdf info for investigation" do
  #     assert_match /rdf:Description.+rdf:about.+\/id\/investigations\/#{@investigation.id}/, @response.body
  #     assert_match /rdf:Description.+rdfs:label>#{@investigation.title}/m, @response.body
  #     assert_match /foaf:phone.+#{Regexp.escape(@investigation.foaf_telephone)}/, @response.body
  #     assert_match /foaf:homepage>#{Regexp.escape(@investigation.url)}/m, @response.body
  #     assert_match /vCard:Extadd.+#{Regexp.escape(@investigation.address)}/, @response.body
  #   end
  # 
  #   should "show investigation is same as dbpedia entry" do
  #     assert_match /owl:sameAs.+rdf:resource.+dbpedia.+SomeForce/, @response.body
  #   end
  # 
  #   should "show associated police force" do
  #     assert_match /openlylocal:isInvestigationFor.+rdf:resource.+\/id\/police_forces\/#{@police_force.id}/, @response.body
  #     assert_match /rdf:Description.+\/id\/police_forces\/#{@police_force.id}/, @response.body
  #   end
  
  end
  
  context "with json request" do
  
    setup do
      @investigation
      get :show, :id => @investigation.id, :format => "json"
    end
  
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/json'
  
  #   should "include attributes in response" do
  #     assert_match /investigation\":.+address\":/, @response.body
  #   end
  # 
  #   should "include councils and basic council data in response" do
  #     assert_match /investigation\":.+name.+#{@council.name}/, @response.body
  #     assert_match /investigation\":.+councils\":.+id\":#{@council.id}/, @response.body
  #     assert_match /investigation\":.+councils\":.+#{Regexp.escape(@council.url)}/, @response.body
  #   end
  # 
  #   should "not include non-essential council data in response" do
  #     assert_no_match %r(council\":.+investigation_id), @response.body
  #     assert_no_match %r(council\":.+wdtk_name), @response.body
  #   end   
  end
end
