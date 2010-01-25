require 'test_helper'

class PoliceAuthoritiesControllerTest < ActionController::TestCase
  def setup
    @police_authority = Factory(:police_authority)
    @police_force = @police_authority.police_force
    @council = Factory(:council, :police_force_id => @police_force.id)
  end
  
  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to(:police_authorities) { PoliceAuthority.find(:all)}
      should_respond_with :success
      should_render_template :index
      should "list police authorities" do
        assert_select "li a", @police_authority.name
      end

      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /police authorities/i
      end
    end
    
    context "with xml request" do
      setup do
        @police_authority.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
        get :index, :format => "xml"
      end

      should_assign_to(:police_authorities) { PoliceAuthority.find(:all) }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should_assign_to(:police_authorities) { PoliceAuthority.find(:all) }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
    end
    
  end  

  # show test
  context "on GET to :show" do
    setup do
      get :show, :id => @police_authority.id
    end
  
    should_assign_to(:police_authority) { @police_authority}
    should_respond_with :success
    should_render_template :show
    should_render_with_layout
  
    should "list all associated councils" do
      assert_select "#councils li", @police_authority.councils.size do
        assert_select "a", @council.title
      end
    end
    
    should "link to associated police_force" do
      assert_select ".attributes a", @police_force.name
    end
    
    should "show police_authority in title" do
      assert_select "title", /#{@police_authority.name}/
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
      @police_authority.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
      get :show, :id => @police_authority.id, :format => "xml"
    end
  
    should_assign_to(:police_authority) { @police_authority}
    should_respond_with :success
    should_render_without_layout
    should_respond_with_content_type 'application/xml'
    
    should "include attributes in response" do
      assert_select "police-authority>address"
    end
    
    should "include councils and basic council data in response" do
      assert_select "police-authority council name", @council.name
      assert_select "police-authority council id", @council.id.to_s
      assert_select "police-authority council url", @council.url
      assert_select "police-authority council openlylocal-url", @council.openlylocal_url
    end
  
    should "not include non-essential council data in response" do
      assert_select "police-authority council police-authority-id", false
      assert_select "police-authority council wdtk-name", false
    end
  
  end
   
  context "with rdf request" do
    setup do
      @police_authority.update_attributes(:address => "35 Some St, Anytown AN1 2NT", :telephone => "0123 456 789", :wikipedia_url => "http://en.wikipedia.org/wiki/SomeForce")
      get :show, :id => @police_authority.id, :format => "rdf"
    end
   
    should_assign_to(:police_authority) { @police_authority}
    should_respond_with :success
    should_render_without_layout
    should_respond_with_content_type 'application/rdf+xml'
   
    should "show rdf headers" do
      assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
      assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
      assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
    end
  
    should "show alternative representations" do
      assert_match /dct:hasFormat rdf:resource.+\/police_authorities\/#{@police_authority.id}.rdf/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_authorities\/#{@police_authority.id}\"/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_authorities\/#{@police_authority.id}.json/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_authorities\/#{@police_authority.id}.xml/m, @response.body
    end
    
    should "show police_authority as primary resource" do
      assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/police_authorities\/#{@police_authority.id}/m, @response.body
    end
    
    should "show rdf info for police_authority" do
      assert_match /rdf:Description.+rdf:about.+\/id\/police_authorities\/#{@police_authority.id}/, @response.body
      assert_match /rdf:Description.+rdfs:label>#{@police_authority.title}/m, @response.body
      assert_match /foaf:phone.+#{Regexp.escape(@police_authority.foaf_telephone)}/, @response.body
      assert_match /foaf:homepage>#{Regexp.escape(@police_authority.url)}/m, @response.body
      assert_match /vCard:Extadd.+#{Regexp.escape(@police_authority.address)}/, @response.body
    end
  
    should "show police_authority is same as dbpedia entry" do
      assert_match /owl:sameAs.+rdf:resource.+dbpedia.+SomeForce/, @response.body
    end
    
    should "show associated police force" do
      assert_match /openlylocal:isPoliceAuthorityFor.+rdf:resource.+\/id\/police_forces\/#{@police_force.id}/, @response.body
      assert_match /rdf:Description.+\/id\/police_forces\/#{@police_force.id}/, @response.body
    end
  
  end
  
   context "with json request" do

     setup do
       @police_authority.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
       get :show, :id => @police_authority.id, :format => "json"
     end
  
     should_respond_with :success
     should_render_without_layout
     should_respond_with_content_type 'application/json'
     
     should "include attributes in response" do
       assert_match /police_authority\":.+address\":/, @response.body
     end
     
     should "include councils and basic council data in response" do
       assert_match /police_authority\":.+name.+#{@council.name}/, @response.body
       assert_match /police_authority\":.+councils\":.+id\":#{@council.id}/, @response.body
       assert_match /police_authority\":.+councils\":.+#{Regexp.escape(@council.url)}/, @response.body
     end
  
     should "not include non-essential council data in response" do
       assert_no_match %r(council\":.+police_authority_id), @response.body
       assert_no_match %r(council\":.+wdtk_name), @response.body
     end   
   end
   
   # edit tests
   context "on get to :edit a ward without auth" do
     setup do
       get :edit, :id => @police_authority.id
     end

     should_respond_with 401
   end

   context "on get to :edit a police_authority" do
     setup do
       stub_authentication
       get :edit, :id => @police_authority.id
     end

     should_assign_to :police_authority
     should_respond_with :success
     should_render_template :edit
     should_not_set_the_flash
     should "display a form" do
      assert_select "form#edit_police_authority_#{@police_authority.id}"
     end

   end

   # update tests
   context "on PUT to :update without auth" do
     setup do
       put :update, { :id => @police_authority.id,
                      :police_authority => { :name => "New name"}}
     end

     should_respond_with 401
   end

   context "on PUT to :update" do
     setup do
       stub_authentication
       put :update, { :id => @police_authority.id,
                      :police_authority => { :name => "New name"}}
     end

     should_assign_to :police_authority
     should_redirect_to( "the show page for police_authority") { police_authority_path(@police_authority.reload) }
     should_set_the_flash_to "Successfully updated police authority"

     should "update police_authority" do
       assert_equal "New name", @police_authority.reload.name
     end
   end
   
end
