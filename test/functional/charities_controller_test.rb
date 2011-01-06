require 'test_helper'

class CharitiesControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def setup
    @charity = Factory(:charity)
  end
  
  context "on GET to :show" do
    context "in general" do
      setup do
        get :show, :id => @charity.id
      end

      should assign_to(:charity) { @charity}
      should respond_with :success
      should render_template :show

      should "show charity name in title" do
        assert_select "title", /#{@charity.title}/
      end

      should "show api block" do
        assert_select "#api_info"
      end
    end
    
    context "when charity has supplying relationships" do
      setup do
        @supplier = Factory(:supplier, :payee => @charity)
        get :show, :id => @charity.id
      end

      should 'list suppliers as organisation' do
        assert_select 'li .supplier_link', /#{@supplier.organisation.title}/
      end
    end
    
    context "with xml request" do
      setup do
        @accounts_info = [{ :accounts_date => '31 Mar 2009', :income => '1234', :spending => '2345', :accounts_url => 'http://charitycommission.gov.uk/accounts2.pdf'}]
        @charity.update_attribute(:accounts, @accounts_info)
        get :show, :id => @charity.id, :format => "xml"
      end

      should assign_to(:charity) { @charity}
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/xml'

      should "include attributes in response" do
        assert_select "charity>title"
      end

      should "not include email in response" do
        assert_select "charity>email", false
      end

      should_eventually "include accounts in response" do
        assert_select "charity>accounts>account>spending"
      end

    end

    context "with rdf request" do
      setup do
        @charity.update_attributes(:telephone => '012 345 678', :website => 'http://charity.com')
        get :show, :id => @charity.id, :format => "rdf"
      end

      should assign_to(:charity) { @charity}
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/rdf+xml'

      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end

      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}\"/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.xml/m, @response.body
      end

      should "show charity as primary resource" do
        assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/charities\/#{@charity.id}/m, @response.body
      end

      should "show rdf info for charity" do
        assert_match /rdf:Description.+rdf:about.+\/id\/charities\/#{@charity.id}/, @response.body
        assert_match /rdf:Description.+rdfs:label>#{@charity.title}/m, @response.body
        assert_match /foaf:phone.+#{Regexp.escape(@charity.foaf_telephone)}/, @response.body
        assert_match /foaf:homepage>#{Regexp.escape(@charity.website)}/m, @response.body
        # assert_match /vCard:Extadd.+#{Regexp.escape(@charity.address_in_full)}/, @response.body
      end

      should "show charity is same as opencharities entry" do
        assert_match /owl:sameAs.+rdf:resource.+opencharities.+#{@charity.charity_number}/, @response.body
      end

    end

     context "with json request" do

       setup do
         @charity.update_attribute(:email, 'foo@charity.com')
         get :show, :id => @charity.id, :format => "json"
       end

       should respond_with :success
       should_render_without_layout
       should respond_with_content_type 'application/json'

       should "include attributes in response" do
         assert_match /charity\":.+title\":/, @response.body
       end

       should "not include email in response" do
         assert_no_match /charity\":.+email\":/, @response.body
       end

     end
  end
end
