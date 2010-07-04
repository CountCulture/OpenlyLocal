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

      # should "show organisation name in title" do
      #   assert_select "title", /#{@quango.organisation.title}/
      # end
      # 
      # should "list financial transactions" do
      #   assert_select "#financial_transactions .value", /#{@financial_transaction.value}/
      # end
      # 
      # should "show link to add company details" do
      #   assert_select 'a[href*=user_submissions/new]', /add/i
      # end
    end
    
  end
end
