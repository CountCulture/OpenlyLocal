require 'test_helper'

class PoliceForcesControllerTest < ActionController::TestCase
  def setup
    @police_force = Factory(:police_force)
    @council = Factory(:council, :police_force_id => @police_force.id)
    @police_authority = Factory(:police_authority, :police_force => @police_force)
  end
  
  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should assign_to(:police_forces) { PoliceForce.find(:all)}
      should respond_with :success
      should render_template :index
      
      should "list police forces" do
        assert_select "li a", @police_force.name
      end
      
      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /police forces/i
      end
      
    end
    
    context "with xml request" do
      setup do
        @police_force.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
        get :index, :format => "xml"
      end

      should assign_to(:police_forces) { PoliceForce.find(:all) }
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/xml'
      should "not include npia_id" do
        assert_no_match /<npia-id/, @response.body
      end
    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should assign_to(:police_forces) { PoliceForce.find(:all) }
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
    end
    
  end  

  # show test
  context "on GET to :show" do
    setup do
      @police_team = Factory(:police_team, :police_force => @police_force)
      @defunkt_police_team = Factory(:police_team, :police_force => @police_force, :defunkt => true)
      get :show, :id => @police_force.id
    end
  
    should assign_to(:police_force) { @police_force}
    should respond_with :success
    should render_template :show
    should_render_with_layout
  
    should "list all associated councils" do
      assert_select "#councils li", @police_force.councils.size do
        assert_select "a", @council.title
      end
    end
    
    should "list all associated police_teams" do
      assert_select "#police_teams li", @police_force.police_teams.current.size do
        assert_select "a", @police_team.title
      end
    end
    
    should "not list defunkt teams" do
      assert_select "a", :text => @defunkt_police_team.name, :count => 0
    end

    should "show police_force in title" do
      assert_select "title", /#{@police_force.name}/
    end
    
    should 'show associated police_authority' do
      assert_select ".attributes a", @police_authority.name
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
      @police_force.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
      get :show, :id => @police_force.id, :format => "xml"
    end
  
    should assign_to(:police_force) { @police_force}
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/xml'
    
    should "include attributes in response" do
      assert_select "police-force>address"
    end
    
    should "not include npia_id" do
      assert_no_match /<npia-id/, @response.body
    end
    
    should "include councils and basic council data in response" do
      assert_select "police-force council name", @council.name
      assert_select "police-force council id", @council.id.to_s
      assert_select "police-force council url", @council.url
      assert_select "police-force council openlylocal-url", @council.openlylocal_url
    end
  
    should "not include non-essential council data in response" do
      assert_select "police-force council police-force-id", false
      assert_select "police-force council wdtk-name", false
    end
  
  end
   
  context "with rdf request" do
    setup do
      @police_force.update_attributes(:address => "35 Some St, Anytown AN1 2NT", :telephone => "0123 456 789", :wikipedia_url => "http://en.wikipedia.org/wiki/SomeForce")
      get :show, :id => @police_force.id, :format => "rdf"
    end
   
    should assign_to(:police_force) { @police_force}
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/rdf+xml'
   
    should "show rdf headers" do
      assert_match /rdf:RDF.+ xmlns:foaf/m, @response.body
      assert_match /rdf:RDF.+ xmlns:openlylocal/m, @response.body
      assert_match /rdf:RDF.+ xmlns:administrative-geography/m, @response.body
    end
  
    should "show alternative representations" do
      assert_match /dct:hasFormat rdf:resource.+\/police_forces\/#{@police_force.id}.rdf/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_forces\/#{@police_force.id}\"/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_forces\/#{@police_force.id}.json/m, @response.body
      assert_match /dct:hasFormat rdf:resource.+\/police_forces\/#{@police_force.id}.xml/m, @response.body
    end
    
    should "show police_force as primary resource" do
      assert_match /rdf:Description.+foaf:primaryTopic.+\/id\/police_forces\/#{@police_force.id}/m, @response.body
    end
    
    should "show rdf info for police_force" do
      assert_match /rdf:Description.+rdf:about.+\/id\/police_forces\/#{@police_force.id}/, @response.body
      assert_match /rdf:Description.+rdfs:label>#{@police_force.title}/m, @response.body
      assert_match /foaf:phone.+#{Regexp.escape(@police_force.foaf_telephone)}/, @response.body
      assert_match /foaf:homepage>#{Regexp.escape(@police_force.url)}/m, @response.body
      assert_match /vCard:Extadd.+#{Regexp.escape(@police_force.address)}/, @response.body
    end
  
    should "show police_force is same as dbpedia entry" do
      assert_match /owl:sameAs.+rdf:resource.+dbpedia.+SomeForce/, @response.body
    end
    
    should "show associated councils" do
      assert_match /openlylocal:isPoliceForceFor.+rdf:resource.+\/id\/councils\/#{@council.id}/, @response.body
      assert_match /rdf:Description.+\/id\/councils\/#{@council.id}/, @response.body
    end
  
  end
  
   context "with json request" do

     setup do
       @police_force.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
       get :show, :id => @police_force.id, :format => "json"
     end
  
     should respond_with :success
     should_render_without_layout
     should respond_with_content_type 'application/json'
     
     should "include attributes in response" do
       assert_match /police_force\":.+address\":/, @response.body
     end
     
     should "include councils and basic council data in response" do
       assert_match /police_force\":.+name.+#{@council.name}/, @response.body
       assert_match /police_force\":.+councils\":.+id\":#{@council.id}/, @response.body
       assert_match /police_force\":.+councils\":.+#{Regexp.escape(@council.url)}/, @response.body
     end
  
     should "not include non-essential council data in response" do
       assert_no_match %r(council\":.+police_force_id), @response.body
       assert_no_match %r(council\":.+wdtk_name), @response.body
     end
    
   end
   
  # new test
  context "on GET to :new without auth" do
    setup do
      get :new
    end
  
    should respond_with 401
  end

  context "on GET to :new" do
    setup do
      stub_authentication
      get :new
    end
  
    should assign_to(:police_force)
    should respond_with :success
    should render_template :new
  
    should "show form" do
      assert_select "form#new_police_force"
    end
  end  
  
  # create test
   context "on POST to :create" do
    
     context "without auth" do
       setup do
         post :create, :police_force => {:name => "New Force", :url => "http:://new_force.com"}
       end

       should respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :police_force => {:name => "New Force", :url => "http:://new_force.com"}
       end
     
       should_change("The number of police_forces", :by => 1) { PoliceForce.count }
       should assign_to :police_force
       should_redirect_to( "the show page for police_force") { police_force_path(assigns(:police_force)) }
       should_set_the_flash_to "Successfully created police force"
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :police_force => {:url => "http:://new_force.com"}
       end
     
       should_not_change("The number of police_forces") { PoliceForce.count }
       should assign_to :police_force
       should render_template :new
       should_not set_the_flash
     end
  
   end  
  
   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @police_force
     end

     should respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @police_force
     end
  
     should assign_to(:police_force)
     should respond_with :success
     should render_template :edit
  
     should "show form" do
       assert_select "form#edit_police_force_#{@police_force.id}"
     end
   end  
  
  # update test
  context "on PUT to :update" do
    context "without auth" do
      setup do
        put :update, :id => @police_force.id, :police_force => { :name => "New Name", :url => "http://new.name.com"}
      end

      should respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @police_force.id, :police_force => { :name => "New Name", :url => "http://new.name.com"}
      end
    
      should_not_change("The number of police_forces") { PoliceForce.count }
      should_change("The police_force name", :to => "New Name") { @police_force.reload.name }
      should_change("The police_force url", :to => "http://new.name.com") { @police_force.reload.url }
      should assign_to :police_force
      should_redirect_to( "the show page for police force") { police_force_path(assigns(:police_force)) }
      should_set_the_flash_to "Successfully updated police force"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @police_force.id, :police_force => {:name => ""}
      end
    
      should_not_change("The number of police_forces") { PoliceForce.count }
      should_not_change("The police_force name") { @police_force.reload.name }
      should assign_to :police_force
      should render_template :edit
      should_not set_the_flash
    end
  
  end  

end
