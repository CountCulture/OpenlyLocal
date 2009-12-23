require 'test_helper'

class HyperlocalSitesControllerTest < ActionController::TestCase
  def setup
    @hyperlocal_site = Factory(:hyperlocal_site)
  end

  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @hyperlocal_site.id
      end

      should_assign_to :hyperlocal_site
      should_respond_with :success
      should_render_template :show

      should "include hyperlocal site in page title" do
        assert_select "title", /#{@hyperlocal_site.title}/
      end

      should "list hyperlocal site attributes" do
        assert_select '.attributes dd', /#{@hyperlocal_site.url}/
      end
    end
    
    context "when hyperlocal_site belongs to hyperlocal_group" do
      setup do
        @hyperlocal_group = Factory(:hyperlocal_group)
        @hyperlocal_group.hyperlocal_sites << @hyperlocal_site
        get :show, :id => @hyperlocal_site.id
      end
      
      should "list hyperlocal group" do
        assert_select '.attributes dd a', @hyperlocal_group.title
      end
      
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
  
    should_assign_to(:hyperlocal_site)
    should_respond_with :success
    should_render_template :new
  
    should "show form" do
      assert_select "form#new_hyperlocal_site"
    end
  end  
  
  # create test
   context "on POST to :create" do
    
     context "without auth" do
       setup do
         post :create, :hyperlocal_site => {:title => "New Hyperlocal Site", :url => "http:://hyperlocal_site.com"}
       end

       should_respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_site => {:title => "New Hyperlocal Site", :url => "http:://hyperlocal_group.com"}
       end
     
       should_change "HyperlocalSite.count", :by => 1
       should_assign_to :hyperlocal_site
       should_redirect_to( "the show page for hyperlocal_site") { hyperlocal_site_url(assigns(:hyperlocal_site)) }
       should_set_the_flash_to /Successfully created/
     
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_site => {:title => "New Hyperlocal Site"}
       end
     
       should_not_change "HyperlocalSite.count"
       should_assign_to :hyperlocal_site
       should_render_template :new
       should_not_set_the_flash
     end
  
   end  
  
  # edit tests
  context "on get to :edit a hyperlocal site without auth" do
    setup do
      get :edit, :id => @hyperlocal_site.id
    end

    should_respond_with 401
  end

  context "on get to :edit a hyperlocal site" do
    setup do
      stub_authentication
      get :edit, :id => @hyperlocal_site.id
    end

    should_assign_to :hyperlocal_site
    should_respond_with :success
    should_render_template :edit
    should_not_set_the_flash
    should "display a form" do
     assert_select "form#edit_hyperlocal_site_#{@hyperlocal_site.id}"
    end

  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @hyperlocal_site.id,
                     :hyperlocal_site => { :title => "New title"}}
    end

    should_respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @hyperlocal_site.id,
                     :hyperlocal_site => { :title => "New title"}}
    end

    should_assign_to :hyperlocal_site
    should_redirect_to( "the show page for hyperlocal_site") { hyperlocal_site_url(@hyperlocal_site.reload) }
    should_set_the_flash_to /Successfully updated/

    should "update hyperlocal_site" do
      assert_equal "New title", @hyperlocal_site.reload.title
    end
  end
end
