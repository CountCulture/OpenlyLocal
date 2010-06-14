require 'test_helper'

class SuppliersControllerTest < ActionController::TestCase
  def setup
    @supplier = Factory(:supplier)
    @financial_transaction = Factory(:financial_transaction, :supplier => @supplier)
  end
  
  context "on GET to :show" do
    setup do
      get :show, :id => @supplier.id
    end

    should_assign_to(:supplier) { @supplier}
    should respond_with :success
    should render_template :show
    should_assign_to(:organisation) { @organisation }

    should "show supplier name in title" do
      assert_select "title", /#{@supplier.title}/
    end

    should "show list financial transactions" do
      assert_select "#financial_transactions .value", /#{@financial_transaction.value}/
    end

  end  

  context "with xml requested" do
    setup do
      get :show, :id => @supplier.id, :format => "xml"
    end

    should_assign_to(:supplier) { @supplier }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/xml'
    should "include financial_transactions" do
      assert_select "supplier>financial-transactions>financial-transaction>id", "#{@financial_transaction.id}"
    end
  end

  context "with json requested" do
    setup do
      get :show, :id => @supplier.id, :format => "json"
    end

    should_assign_to(:supplier) { @supplier }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/json'
    should "include financial_transactions" do
      assert_match /supplier\":.+financial_transactions\":.+id\":#{@financial_transaction.id}/, @response.body
    end
  end

end
