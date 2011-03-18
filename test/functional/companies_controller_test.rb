require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  def setup
    @company = Factory(:company)
    @supplier = Factory(:supplier, :payee => @company)
  end
  
  
  context "on GET to :spending" do

    setup do
      @financial_transactions = [Factory(:financial_transaction)]
      @charities = [Factory(:charity, :spending_stat => Factory(:spending_stat))]
      @companies = [Factory(:company, :spending_stat => Factory(:spending_stat))]

      @cached_spending_data = { :supplier_count=>77665, 
                                :largest_transactions=>@financial_transactions, 
                                :largest_companies=>@companies, 
                                :total_spend=>3404705734.99, 
                                :company_count=>27204, 
                                :largest_charities=>@charities, 
                                :transaction_count=>476422}
      @high_spending_council = Factory(:council, :name => "High Spender")
      Council.stubs(:cached_spending_data).returns(@cached_spending_data)
      # 20.times do
      #   c = Factory(:company)
      #   Factory(:spending_stat, :organisation => c, :total_spend => 500)
      # end
      # @big_company = Factory(:company)
      # Factory(:spending_stat, :organisation => @big_company, :total_spend => 999999)
      get :spending
    end

    should assign_to(:council_spending_data){@cached_spending_data}
    should respond_with :success
    should render_template :spending

    should "show title" do
      assert_select "title", /companies supplying/i
    end

    should 'list largest companies' do
      assert_select 'table .company_link', /#{@companies.first.title}/
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

      should "show OpenCorporates resource uri as main subject in head" do
        assert_select "link[rel=primarytopic][href='http://opencorporates.com/id/companies/gb/#{@company.company_number}']"
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
        @org1 = Factory(:generic_council)
        @org2 = Factory(:police_authority)
        @org3 = Factory(:generic_council)
        @earliest_date = '2008-03-23'.to_date
        @latest_date = '2008-02-04'.to_date
        
        payer_breakdown = [{ :organisation_id => @org1.id, 
                             :organisation_type => @org1.class.to_s, 
                             :total_spend => 321.4, 
                             :transaction_count => 1,
                             :average_transaction_value => 321.4},
                           { :organisation_id => @org2.id, 
                             :organisation_type => @org2.class.to_s, 
                             :total_spend => 111111.1, 
                             :transaction_count => 21,
                             :average_transaction_value => 42.323},
                           { :organisation_id => @org3.id, 
                             :organisation_type => @org3.class.to_s, 
                             :total_spend => 222.2, 
                             :transaction_count => 2,
                             :average_transaction_value => 102.2} ]
        
        Factory(:spending_stat, :organisation => @company, 
                                :total_spend => 999999, 
                                :transaction_count => 42,                                
                                :average_transaction_value => 321.4,
                                :earliest_transaction => @earliest_date,
                                :latest_transaction => @latest_date,
                                :payer_breakdown => payer_breakdown )
        get :show, :id => @company.id
      end


      should "show dashboard" do
        assert_select ".dashboard"
      end
      
      should "show number of councils supplying" do
        assert_select ".dashboard h3", /2 councils/
      end
      
      should "show payer_breakdown table" do
        assert_select "table#payer_breakdown"
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
