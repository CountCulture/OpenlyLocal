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
