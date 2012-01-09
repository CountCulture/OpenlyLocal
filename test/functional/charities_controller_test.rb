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

      should "show OpenCharities resource uri as main subject in head" do
        assert_select "link[rel=primarytopic][href='http://opencharities.org/id/charities/#{@charity.charity_number}']"
      end

      should "show api block" do
        assert_select "#api_info"
      end
    end
    
    context "when charity is dissolved" do
      setup do
        @charity.update_attributes(:telephone => '1234 5678', :date_removed => 5.days.ago)
        get :show, :id => @charity.id
      end

      should respond_with :success

      should "not show telephone" do
        assert_select ".telephone", false
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
      should_not render_with_layout
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
      should_not render_with_layout
      should respond_with_content_type 'application/rdf+xml'

      should "show rdf headers" do
        assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
        assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
        assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
      end

      should "identify this page being about opencharities charity resource uri" do
        assert_match /rdf:Description.+rdf:about.+opencharities.+#{@charity.charity_number}/, @response.body
      end

      should "show rdf info for charity" do
        assert_match /rdf:Description.+rdfs:label>#{@charity.title}/m, @response.body
        assert_match /foaf:phone.+#{Regexp.escape(@charity.foaf_telephone)}/, @response.body
        assert_match /foaf:homepage>#{Regexp.escape(@charity.website)}/m, @response.body
        assert_match /dct:modified.+#{Regexp.escape(@charity.updated_at.xmlschema)}/m, @response.body
      end

      should "show alternative representations" do
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.rdf/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.html/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.json/m, @response.body
        assert_match /dct:hasFormat rdf:resource.+\/charities\/#{@charity.id}.xml/m, @response.body
      end

      should "show opencharities charity as primary resource for representations" do
        assert_match /rdf:Description.+foaf:primaryTopic.+opencharities.+#{@charity.charity_number}/m, @response.body
      end

    end

     context "with json request" do

       setup do
         @charity.update_attribute(:email, 'foo@charity.com')
         get :show, :id => @charity.id, :format => "json"
       end

       should respond_with :success
       should_not render_with_layout
       should respond_with_content_type 'application/json'

       should "include attributes in response" do
         assert_match /charity\":.+title\":/, @response.body
       end

       should "not include email in response" do
         assert_no_match %r(charity\":.+email\":), @response.body
       end

     end
  end

   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @charity
     end

     should respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @charity
     end
  
     should assign_to(:charity)
     should respond_with :success
     should render_template :edit
  
     should "show form" do
       assert_select "form#edit_charity_#{@charity.id}"
     end
   end  
  
  # update test
  context "on PUT to :update" do
    context "without auth" do
      setup do
        put :update, :id => @charity.id, :charity => { :title => "New Name", :website => "http://new.name.com"}
      end

      should respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @charity.id, :charity => { :website => "http://new.name.com"}
      end
    
      should_change("The charity website", :to => "http://new.name.com") { @charity.reload.website }
      should assign_to :charity
      should redirect_to( "the show page for charity") { charity_path(assigns(:charity)) }
      should_set_the_flash_to "Successfully updated charity"
      
      should "not set the manually_updated flag for the charity" do
        assert_in_delta @charity.reload.manually_updated, Time.now, 2
      end
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @charity.id, :charity => {:title => ""}
      end
    
      should_not_change("The charity name") { @charity.reload.title }
      should assign_to :charity
      should render_template :edit
      should_not set_the_flash
    end
  
  end  
  
  context "on PUT to :refresh" do
    context "in general" do
      setup do
        put :refresh, :id => @charity.id
      end
    
      should assign_to :charity
      should redirect_to( "the show page for charity") { charity_path(assigns(:charity)) }
      
      should "add to delayed job queue" do
        Delayed::Job.expects(:enqueue).with(kind_of(Charity))
        put :refresh, :id => @charity.id
      end
      
      should "not set the manually_updated flag for the charity" do
        assert_nil @charity.manually_updated
      end
      
    end
    
    context "with xhr request" do
      setup do
        xhr :put, :refresh, :id => @charity.id
      end
      
      should respond_with :success

      should "add to delayed job queue" do
        Delayed::Job.expects(:enqueue).with(kind_of(Charity))
        xhr :put, :refresh, :id => @charity.id
      end
    end
    
    
  end
end
