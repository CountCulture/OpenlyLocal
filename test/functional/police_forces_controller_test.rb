require 'test_helper'

class PoliceForcesControllerTest < ActionController::TestCase
  def setup
    @police_force = Factory(:police_force)
  end
  
  # index test
  context "on GET to :index" do
    setup do
      get :index
    end
  
    should_assign_to(:police_forces) { PoliceForce.find(:all)}
    should_respond_with :success
    should_render_template :index
    should "list police forces" do
      assert_select "li a", @police_force.name
    end
    
    should "show share block" do
      assert_select "#share_block"
    end
    
    should_eventually "show api block" do
      assert_select "#api_info"
    end
  end  

  # show test
  context "on GET to :show" do
    setup do
      @council = Factory(:council, :police_force_id => @police_force.id)
      get :show, :id => @police_force.id
    end
  
    should_assign_to(:police_force) { @police_force}
    should_respond_with :success
    should_render_template :show
  
    should "list all associated councils" do
      assert_select "#councils li", @police_force.councils.size do
        assert_select "a", @council.title
      end
    end
    
    should "show share block" do
      assert_select "#share_block"
    end
    
    should_eventually "show api block" do
      assert_select "#api_info"
    end
  end  
  
  # new test
  context "on GET to :new without auth" do
    setup do
      get :new
    end
  
    should_respond_with 401
  end

  context "on GET to :new" do
    setup do
      stub_authentication
      get :new
    end
  
    should_assign_to(:police_force)
    should_respond_with :success
    should_render_template :new
  
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

       should_respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :police_force => {:name => "New Force", :url => "http:://new_force.com"}
       end
     
       should_change "PoliceForce.count", :by => 1
       should_assign_to :police_force
       should_redirect_to( "the show page for police_force") { police_force_path(assigns(:police_force)) }
       should_set_the_flash_to "Successfully created police force"
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :police_force => {:url => "http:://new_force.com"}
       end
     
       should_not_change "PoliceForce.count"
       should_assign_to :police_force
       should_render_template :new
       should_not_set_the_flash
     end
  
   end  
  
   # edit test
   context "on GET to :edit without auth" do
     setup do
       get :edit, :id => @police_force
     end

     should_respond_with 401
   end

   context "on GET to :edit with existing record" do
     setup do
       stub_authentication
       get :edit, :id => @police_force
     end
  
     should_assign_to(:police_force)
     should_respond_with :success
     should_render_template :edit
  
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

      should_respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @police_force.id, :police_force => { :name => "New Name", :url => "http://new.name.com"}
      end
    
      should_not_change "PoliceForce.count"
      should_change "@police_force.reload.name", :to => "New Name"
      should_change "@police_force.reload.url", :to => "http://new.name.com"
      should_assign_to :police_force
      should_redirect_to( "the show page for police force") { police_force_path(assigns(:police_force)) }
      should_set_the_flash_to "Successfully updated police force"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @police_force.id, :police_force => {:name => ""}
      end
    
      should_not_change "PoliceForce.count"
      should_not_change "@police_force.reload.name"
      should_assign_to :police_force
      should_render_template :edit
      should_not_set_the_flash
    end
  
  end  

end
