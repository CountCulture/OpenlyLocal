require 'test_helper'

class QuangosControllerTest < ActionController::TestCase
  def setup
    @quango = Factory(:quango)
  end
  
  context "on GET to :index" do
    
    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to(:quangos) { Quango.find(:all)}
      should respond_with :success
      should render_template :index
      should "list quangos" do
        assert_select "li a", @quango.title
      end
      
      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /quangos/i
      end
    end
    
    context "with xml request" do
      setup do
        get :index, :format => "xml"
      end

      should_assign_to(:quangos) { Quango.find(:all) }
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/xml'
    end

    context "with json requested" do
      setup do
        get :index, :format => "json"
      end

      should_assign_to(:quangos) { Quango.find(:all) }
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
    end
  end
  
  context "on GET to :show" do
    context "in general" do
      setup do
        get :show, :id => @quango.id
      end

      should assign_to(:quango) { @quango}
      should respond_with :success
      should render_template :show
      # should assign_to(:organisation) { @organisation }

      should "show quango name in title" do
        assert_select "title", /#{@quango.title}/
      end

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
  
    should_assign_to(:quango)
    should respond_with :success
    should render_template :new
  
    should "show form" do
      assert_select "form#new_quango"
    end
  end  
  
  # create test
   context "on POST to :create" do
    
     context "without auth" do
       setup do
         post :create, :quango => {:title => "New Quango", :website => "http:://new_quango.com"}
       end

       should respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :quango => {:title => "New Quango", :website => "http:://new_quango.com"}
       end
     
       should_change("The number of quangos", :by => 1) { Quango.count }
       should_assign_to :quango
       should_redirect_to( "the show page for quango") { quango_path(assigns(:quango)) }
       should_set_the_flash_to "Successfully created quango"
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :quango => {:website => "http:://new_force.com"}
       end
     
       should_not_change("The number of quangos") { Quango.count }
       should_assign_to :quango
       should render_template :new
       should_not set_the_flash
     end
  
   end  
  
   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @quango
     end

     should respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @quango
     end
  
     should_assign_to(:quango)
     should respond_with :success
     should render_template :edit
  
     should "show form" do
       assert_select "form#edit_quango_#{@quango.id}"
     end
   end  
  
  # update test
  context "on PUT to :update" do
    context "without auth" do
      setup do
        put :update, :id => @quango.id, :quango => { :title => "New Name", :website => "http://new.name.com"}
      end

      should respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @quango.id, :quango => { :title => "New Name", :website => "http://new.name.com"}
      end
    
      should_not_change("The number of quangos") { Quango.count }
      should_change("The quango name", :to => "New Name") { @quango.reload.title }
      should_change("The quango website", :to => "http://new.name.com") { @quango.reload.website }
      should_assign_to :quango
      should_redirect_to( "the show page for quango") { quango_path(assigns(:quango)) }
      should_set_the_flash_to "Successfully updated quango"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @quango.id, :quango => {:title => ""}
      end
    
      should_not_change("The number of quangos") { Quango.count }
      should_not_change("The quango name") { @quango.reload.title }
      should_assign_to :quango
      should render_template :edit
      should_not set_the_flash
    end
  
  end  
  
  # delete tests
  context "on delete to :destroy a quango without auth" do
    setup do
      delete :destroy, :id => @quango.id
    end

    should respond_with 401
  end

  context "on delete to :destroy a quango" do

    setup do
      stub_authentication
      delete :destroy, :id => @quango.id
    end

    should "destroy hyperlocal_site" do
      assert_nil Quango.find_by_id(@quango.id)
    end
    should_redirect_to ( "the quangos page") { quangos_url }
    should set_the_flash.to( /Successfully destroyed/)
  end
  
end
