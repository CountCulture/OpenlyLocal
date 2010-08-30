require 'test_helper'

class CharitiesControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def setup
    @charity = Factory(:charity)
  end
  
  context "on GET to :show" do
    context "in general" do
      setup do
        get :show, :id => @charity.id
      end

      should assign_to(:charity) { @charity}
      should respond_with :success
      should render_template :show

      should "show charity name in title" do
        assert_select "title", /#{@charity.title}/
      end

    end
    
    context "when charity has supplying relationships" do
      setup do
        @supplier = Factory(:supplier, :payee => @charity)
        get :show, :id => @charity.id
      end

      should 'list suppliers as organisation' do
        assert_select 'li .supplier_link', /#{@supplier.organisation.title}/
      end
    end
    
  end
end
