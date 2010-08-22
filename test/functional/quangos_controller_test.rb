require 'test_helper'

class QuangosControllerTest < ActionController::TestCase
  def setup
    @quango = Factory(:quango)
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
