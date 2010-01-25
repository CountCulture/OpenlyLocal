require 'test_helper'

class PensionFundsControllerTest < ActionController::TestCase
  def setup
    @pension_fund = Factory(:pension_fund)
  end
  
  # index test
  context "on GET to :index" do
    
    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to(:pension_funds) { PensionFund.find(:all)}
      should_respond_with :success
      should_render_template :index
      should "list pension funds" do
        assert_select "li a", @pension_fund.name
      end
      
      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /pension funds/i
      end
    end
    
    context "with xml request" do
      setup do
        get :index, :format => "xml"
      end

      should_assign_to(:pension_funds) { PensionFund.find(:all) }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
    end

    context "with json requested" do
      setup do
        get :index, :format => "json"
      end

      should_assign_to(:pension_funds) { PensionFund.find(:all) }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
    end
  end
  
  # show test
  context "on GET to :show" do
    setup do
      @council = Factory(:council, :pension_fund_id => @pension_fund.id)
      get :show, :id => @pension_fund.id
    end
  
    should_assign_to(:pension_fund) { @pension_fund}
    should_respond_with :success
    should_render_template :show
    should_render_with_layout
  
    should 'show title' do
      assert_select "title", /#{@pension_fund.name}/i
    end
    
    should "list all associated councils" do
      assert_select "#councils li", @pension_fund.councils.size do
        assert_select "a", @council.title
      end
    end
  end
  
  # edit tests
  context "on get to :edit a ward without auth" do
    setup do
      get :edit, :id => @pension_fund.id
    end

    should_respond_with 401
  end

  context "on get to :edit a pension_fund" do
    setup do
      stub_authentication
      get :edit, :id => @pension_fund.id
    end

    should_assign_to :pension_fund
    should_respond_with :success
    should_render_template :edit
    should_not_set_the_flash
    should "display a form" do
     assert_select "form#edit_pension_fund_#{@pension_fund.id}"
    end

  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @pension_fund.id,
                     :pension_fund => { :name => "New name"}}
    end

    should_respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @pension_fund.id,
                     :pension_fund => { :name => "New name"}}
    end

    should_assign_to :pension_fund
    should_redirect_to( "the show page for pension_fund") { pension_fund_path(@pension_fund.reload) }
    should_set_the_flash_to "Successfully updated pension fund"

    should "update pension_fund" do
      assert_equal "New name", @pension_fund.reload.name
    end
  end

end
