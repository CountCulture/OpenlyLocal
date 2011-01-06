require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  def setup
    @company = Factory(:company)
    @supplier = Factory(:supplier, :payee => @company)
  end
  
  context "on GET to :show" do
    setup do
      get :show, :id => @company.id
    end

    should assign_to(:company) { @company}
    should respond_with :success
    should render_template :show

    should "show company name in title" do
      assert_select "title", /#{@company.title}/
    end
    
    should 'list suppliers as organisation' do
      assert_select 'li .supplier_link', /#{@supplier.organisation.title}/
    end
    
    should "show api block" do
      assert_select "#api_info"
    end

  end  

  context "with xml requested" do
    setup do
      get :show, :id => @company.id, :format => "xml"
    end

    should assign_to(:company) { @company }
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/xml'
    should "include suppliers" do
      assert_select "supplying-relationships>supplying-relationship>id", "#{@supplier.id}"
    end
    
    should "include supplying organisations" do
      assert_select "supplying-relationships>supplying-relationship>organisation>id", "#{@supplier.organisation.id}"
    end
  end

  context "with json requested" do
    setup do
      get :show, :id => @company.id, :format => "json"
    end

    should assign_to(:company) { @company }
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/json'
    should "include supplying organisations" do
      assert_match /supplying_relationships\":.+id\":#{@supplier.id}/, @response.body
    end
  end
  
  context "with rdf requested" do
    setup do
      @company.update_attributes(:url => 'http://foocorp.com', :address_in_full => '3 Acacia Lane, Footown')
      get :show, :id => @company.id, :format => "rdf"
    end
   
    should assign_to(:company) { @company }
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/rdf+xml'
   
    should "show rdf headers" do
      assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
      assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
      assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
    end
  
    should "show alternative representations" do
      assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.rdf/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}\"/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.json/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.xml/m, @response.body
    end
    
    should "show company as primary resource" do
      assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/companies\/#{@company.id}/m, @response.body
    end
    
    should "show rdf info for company" do
      assert_match /rdf:type.+org\/FormalOrganization/m, @response.body
      assert_match /rdf:Description.+rdf:about.+\/id\/companies\/#{@company.id}/, @response.body
      assert_match /rdf:Description.+rdfs:label>#{@company.title}/m, @response.body
      assert_match /foaf:homepage>#{Regexp.escape(@company.url)}/m, @response.body
      assert_match /vCard:Extadd.+#{Regexp.escape(@company.address_in_full)}/, @response.body
    end
    
    should "show company is same as opencorporates company" do
      assert_match /owl:sameAs.+rdf:resource.+opencorporates.com\/id\/companies\/uk\/#{@company.company_number}/, @response.body
    end    
  end
  

end
