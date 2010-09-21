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
end
