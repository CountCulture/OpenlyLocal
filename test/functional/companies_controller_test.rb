require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  def setup
    @company = Factory(:company)
    @supplier = Factory(:supplier, :payee => @company)
  end
  
  # context "when routing" do
  #   should "route ward identified by snac_id to show action" do
  #     assert_routing "companies/uk/1234", {:controller => "companies", :action => "show", :company_number => "1234", :jurisdiction_code => 'uk'}
  #     assert_routing "companies/uk/1234.xml", {:controller => "companies", :action => "show", :company_number => "1234", :jurisdiction_code => 'uk', :format => "xml"}
  #     assert_routing "companies/uk/1234.json", {:controller => "companies", :action => "show", :company_number => "1234", :jurisdiction_code => 'uk', :format => "json"}
  #     assert_routing "companies/uk/1234.rdf", {:controller => "companies", :action => "show", :company_number => "1234", :jurisdiction_code => 'uk', :format => "rdf"}
  #   end
  # end
  
  context "on GET to :spending" do

    setup do
      20.times do
        c = Factory(:company)
        Factory(:spending_stat, :organisation => c, :total_spend => 500)
      end
      @big_company = Factory(:company)
      Factory(:spending_stat, :organisation => @big_company, :total_spend => 999999)
      get :spending
    end

    should assign_to(:biggest_companies)
    should respond_with :success
    should render_template :spending

    should "show title" do
      assert_select "title", /companies supplying/i
    end

    should 'list largest companies in descending order of total_spend' do
      assert_select 'li .company_link', /#{@big_company.title}/
      assert_equal @big_company, assigns(:biggest_companies).first
    end
  end

  context "on GET to :show" do
    context "in general" do
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

      should "show OpenCorporates resource uri as main subject in head" do
        assert_select "link[rel=primarytopic][href='http://opencorporates.com/id/companies/uk/#{@company.company_number}']"
      end

      should "show api block" do
        assert_select "#api_info"
      end

      should "not show dashboard" do
        assert_select ".dashboard", false
      end
    end
    
    context "when company has spending data" do
      setup do
        20.times do
          c = Factory(:company)
          Factory(:spending_stat, :organisation => c, :total_spend => 500)
        end
        Factory(:spending_stat, :organisation => @company, :total_spend => 999999)
        get :show, :id => @company.id
      end


      should "show dashboard" do
        p @company.spending_stat.blank?
        assert_select ".dashboard"
      end
      
      should "show number of councils supplying" do
        assert_select ".dashboard h3", /supplying 21 councils/
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

      should "identify this page being about opencorporates company resource uri" do
        assert_match /rdf:Description.+rdf:about.+opencorporates.+#{@company.company_number}/, @response.body
      end

      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.html"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/companies\/#{@company.id}.xml/m, @response.body
      end

      should "show rdf info for company for alternative representations" do
        assert_match /rdf:type.+org\/FormalOrganization/m, @response.body
        assert_match /rdf:Description.+rdf:about.+opencorporates.+#{@company.company_number}/, @response.body
        assert_match /rdf:Description.+rdfs:label>#{@company.title}/m, @response.body
        assert_match /foaf:homepage>#{Regexp.escape(@company.url)}/m, @response.body
        assert_match /vCard:Extadd.+#{Regexp.escape(@company.address_in_full)}/, @response.body
      end

    end
  end
end
