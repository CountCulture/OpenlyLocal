require File.expand_path('../../test_helper', __FILE__)

class HyperlocalGroupsControllerTest < ActionController::TestCase
  def setup
    @hyperlocal_group = Factory(:hyperlocal_group, :url => "http://hyperlocal_group.com")
    @hyperlocal_site = Factory(:approved_hyperlocal_site, :hyperlocal_group => @hyperlocal_group)
  end

  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should assign_to(:hyperlocal_groups) { HyperlocalGroup.find(:all)}
      should respond_with :success
      should render_template :index
      should "list hyperlocal groups" do
        assert_select "li a", @hyperlocal_group.title
      end

      should "show share block" do
        assert_select "#share_block"
      end

      should_eventually "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /Hyperlocal Groups/i
      end
      
    end
  end
    
  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @hyperlocal_group.id
      end

      should assign_to :hyperlocal_group
      should respond_with :success
      should render_template :show

      should "include hyperlocal group in page title" do
        assert_select "title", /#{@hyperlocal_group.title}/
      end

      should "list hyperlocal group attributes" do
        assert_select '.attributes dd', /#{@hyperlocal_group.url}/
      end

      should "list associated hyperlocal sites" do
        assert_select 'li a', @hyperlocal_site.title
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
  
    should assign_to(:hyperlocal_group)
    should respond_with :success
    should render_template :new
  
    should "show form" do
      assert_select "form#new_hyperlocal_group"
    end
  end  
  
  # create test
   context "on POST to :create" do
    
     context "without auth" do
       setup do
         post :create, :hyperlocal_group => {:title => "New Hyperlocal Group", :url => "http:://hyperlocal_group.com"}
       end

       should respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_group => {:title => "New Hyperlocal Group", :url => "http:://hyperlocal_group.com"}
       end
     
       should_change( "The number of Hyperlocal groups", :by => 1) { HyperlocalGroup.count }
       should assign_to :hyperlocal_group
       should_redirect_to( "the show page for hyperlocal_group") { hyperlocal_group_url(assigns(:hyperlocal_group)) }
       should_set_the_flash_to /Successfully created/
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_group => {:title => ""}
       end
     
       should_not_change( "The number of Hyperlocal groups") { HyperlocalGroup.count }
       should assign_to :hyperlocal_group
       should render_template :new
       should_not set_the_flash
     end
  
   end  
  
  # edit tests
  context "on get to :edit a hyperlocal group without auth" do
    setup do
      get :edit, :id => @hyperlocal_group.id
    end

    should respond_with 401
  end

  context "on get to :edit a hyperlocal group" do
    setup do
      stub_authentication
      get :edit, :id => @hyperlocal_group.id
    end

    should assign_to :hyperlocal_group
    should respond_with :success
    should render_template :edit
    should_not set_the_flash
    should "display a form" do
     assert_select "form#edit_hyperlocal_group_#{@hyperlocal_group.id}"
    end

  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @hyperlocal_group.id,
                     :hyperlocal_group => { :title => "New title"}}
    end

    should respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @hyperlocal_group.id,
                     :hyperlocal_group => { :title => "New title"}}
    end

    should assign_to :hyperlocal_group
    should_redirect_to( "the show page for hyperlocal_group") { hyperlocal_group_url(@hyperlocal_group.reload) }
    should_set_the_flash_to /Successfully updated/

    should "update hyperlocal_group" do
      assert_equal "New title", @hyperlocal_group.reload.title
    end
  end

end
