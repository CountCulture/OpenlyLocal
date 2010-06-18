require 'test_helper'

class FinancialTransactionsControllerTest < ActionController::TestCase
  def setup
    @financial_transaction = Factory(:financial_transaction)
    @supplier = @financial_transaction.supplier
  end
  
  context "on GET to :show" do
    setup do
      get :show, :id => @financial_transaction.id
    end

    should_assign_to(:financial_transaction) { @financial_transaction }
    should respond_with :success
    should render_template :show
    should_assign_to(:supplier) { @supplier }

    should "show financial_transaction title" do
      assert_select "title", /#{@financial_transaction.reload.title}/ # for some reason reading title as ActiveSupport with Timzeon and so putting time in there. reloading seems to fix it.
    end

  end  

  context "with xml requested" do
    setup do
      get :show, :id => @financial_transaction.id, :format => "xml"
    end

    should_assign_to(:financial_transaction) { @financial_transaction }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/xml'
        
    should "include supplier" do
      # puts css_select('financial-transaction')
      assert_select "financial-transaction>supplier>id", "#{@supplier.id}"
    end
  end

  context "with json requested" do
    setup do
      get :show, :id => @financial_transaction.id, :format => "json"
    end

    should_assign_to(:financial_transaction) { @financial_transaction }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/json'
    should "include supplier" do
      assert_match /financial_transaction\":.+supplier\":.+id\":#{@supplier.id}/, @response.body
    end
  end

end
