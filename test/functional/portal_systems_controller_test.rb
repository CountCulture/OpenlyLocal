require 'test_helper'

class PortalSystemsControllerTest < ActionController::TestCase

  def setup
    @portal = Factory(:portal_system)
  end
  
  # index test
  context "on GET to :index without auth" do
    setup do
      get :index
    end
  
    should respond_with 401
  end

  context "on GET to :index" do
    setup do
      stub_authentication
      get :index
    end
  
    should_assign_to(:portal_systems) { PortalSystem.find(:all)}
    should respond_with :success
    should render_template :index
    should "list portal systems" do
      assert_select "li a", @portal.name
    end
    
    should "not show share block" do
      assert_select "#share_block", false
    end
  end  

  # show test
  context "on GET to :show without auth" do
    setup do
      get :show, :id => @portal.id
    end
  
    should respond_with 401
  end

  context "on GET to :show for first record" do
    setup do
      @council = Factory(:council, :portal_system_id => @portal.id)
      @parser = Factory(:parser, :portal_system => @portal)
      stub_authentication
      get :show, :id => @portal.id
    end
  
    should_assign_to(:portal_system) { @portal}
    should respond_with :success
    should render_template :show
    should_assign_to(:councils) { @portal.councils }
  
    should "list all councils" do
      assert_select "#councils li", @portal.councils.size do
        assert_select "a", @council.title
      end
    end
    
    should "list all parsers" do
      assert_select "#parsers li" do
        assert_select "a", @parser.title
      end
    end
    
    should "not show share block" do
      assert_select "#share_block", false
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
  
    should_assign_to(:portal_system)
    should respond_with :success
    should render_template :new
  
    should "show form" do
      assert_select "form#new_portal_system"
    end
  end  
  
  # create test
   context "on POST to :create" do
    
     context "without auth" do
       setup do
         post :create, :portal_system => {:name => "New Portal", :url => "http:://new_portal.com"}
       end

       should respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :portal_system => {:name => "New Portal", :url => "http:://new_portal.com"}
       end
     
       should_change("The number of portal_systems", :by => 1) { PortalSystem.count }
       should_assign_to :portal_system
       should_redirect_to( "the show page for portal_system") { portal_system_path(assigns(:portal_system)) }
       should_set_the_flash_to "Successfully created portal system"
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :portal_system => {:url => "http:://new_portal.com"}
       end
     
       should_not_change("The number of portal_systems") { PortalSystem.count } 
       should_assign_to :portal_system
       should render_template :new
       should_not set_the_flash
     end
  
   end  
  
   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @portal
     end

     should respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @portal
     end
  
     should_assign_to(:portal_system)
     should respond_with :success
     should render_template :edit
  
     should "show form" do
       assert_select "form#edit_portal_system_#{@portal.id}"
     end
   end  
  
  # update test
  context "on PUT to :update" do
    context "without auth" do
      setup do
        put :update, :id => @portal.id, :portal_system => { :name => "New Name", :url => "http://new.name.com"}
      end

      should respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @portal.id, :portal_system => { :name => "New Name", :url => "http://new.name.com"}
      end
    
      should_not_change("The number of portal_systems") { PortalSystem.count } 
      should_change("The portal_system name", :to => "New Name") { @portal.reload.name }
      should_change("The portal_system url", :to => "http://new.name.com") { @portal.reload.url }
      should_assign_to :portal_system
      should_redirect_to( "the show page for portal system") { portal_system_path(assigns(:portal_system)) }
      should_set_the_flash_to "Successfully updated portal system"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @portal.id, :portal_system => {:name => ""}
      end
    
      should_not_change("The number of portal_systems") { PortalSystem.count } 
      should_not_change("The portal_system name") { @portal.reload.name }
      should_assign_to :portal_system
      should render_template :edit
      should_not set_the_flash
    end
  
  end  

end
