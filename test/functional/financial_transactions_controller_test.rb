require 'test_helper'

class FinancialTransactionsControllerTest < ActionController::TestCase
  def setup
    @financial_transaction = Factory(:financial_transaction, :value => 32.1)
    @supplier = @financial_transaction.supplier
    @organisation = @supplier.organisation
    @big_financial_transaction = Factory(:financial_transaction, :value => 123456.1)
  end
  
  context "on GET to :index" do
    
    context "with basic request" do
      setup do
        get :index
      end
      
      should assign_to(:financial_transactions)
      should respond_with :success
      
      should "show title" do
        assert_select "title", /transactions/i
      end
      
      # should 'list suppliers' do
      #   assert_select 'a.supplier_link', @supplier.name
      # end
      # 
      should 'order by amount' do
        assert_equal @big_financial_transaction, assigns(:financial_transactions).first
      end
      
      # should 'show link to sort by total_spend' do
      #   assert_select 'a.sort', /total spend/i
      # end
            
    end
    
    context 'when enough results' do
      setup do
        30.times { Factory(:financial_transaction) }
      end
      
      context 'in general' do
        setup do
          get :index
        end
        
        should 'show pagination links' do
          assert_select "div.pagination"
        end
        
        should 'show page number in title' do
          assert_select "title", /page 1/i
        end
      end
      
      context "when restriction to organisation" do
        setup do
          get :index, :organisation_type => @organisation.class.to_s, :organisation_id => @organisation.id
        end
        
        should 'restrict to financial transactions for organisation' do
          assert assigns(:financial_transactions).all?{ |ft| ft.supplier.organisation == @organisation  }
        end
        
        should 'show organisation in title' do
          assert_select "title", /#{@organisation.title}/i
        end
      end
      
      context "with xml requested" do
        setup do
          get :index, :format => "xml"
        end
          
        should assign_to(:financial_transactions)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'
          
        should "include suppliers" do
          assert_select "financial-transactions>financial-transaction>id"
        end
          
        should "include supplier" do
          assert_select "financial-transactions>financial-transaction>supplier>id"
        end
          
        should 'include pagination info' do
          assert_select "financial-transactions>total-entries"
        end
      end
      
      context "with json requested" do
        setup do
          get :index, :format => "json"
        end
          
        should assign_to(:financial_transactions)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'
        
        should 'include pagination info' do
          assert_match %r(total_entries), @response.body
          assert_match %r(per_page), @response.body
          assert_match %r(page.+1), @response.body
        end
      end
      
    end
    

  end
  
  context "on GET to :show" do
    context "in general" do

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
      
      should "not show related financial transactions if none" do
        assert_select '#related_transactions', false
      end
    end  

    context "when related transactions" do

      setup do
        @related_transaction = Factory(:financial_transaction, :supplier => @supplier)
        get :show, :id => @financial_transaction.id
      end

      should_assign_to(:financial_transaction) { @financial_transaction }
      should respond_with :success
      should render_template :show
      should_assign_to(:supplier) { @supplier }

      should "show financial_transaction title" do
        assert_select "title", /#{@financial_transaction.reload.title}/ # for some reason reading title as ActiveSupport with Timzeon and so putting time in there. reloading seems to fix it.
      end
      
      should "show related financial transactions" do
        assert_select '#related_transactions'
      end
      
      should "not show FoI request button" do
        assert_select "form#foi_request", false
      end
    end  
    
    context "when transaction value over 10000" do

      setup do
        supplier = Factory(:council_supplier)
        @financial_transaction.update_attributes(:value => 20000, :supplier => supplier)
        
        get :show, :id => @financial_transaction.id
      end

      should_assign_to(:financial_transaction) { @financial_transaction }
      should respond_with :success
      should render_template :show

      should_eventually "show FoI request button" do
        assert_select "form#foi_request"
      end
      
      context "and foi button" do

        should "post to what do they know" do
          
        end

        should "use council whatdotheyknow id" do
          
        end

        should "submit boilerplate" do
          
        end

        should "include transaction details in request details" do
          
        end

        should "submit machine tag" do
          
        end
      end
    end
    
    context "with xml requested" do
      setup do
        get :show, :id => @financial_transaction.id, :format => "xml"
      end

      should_assign_to(:financial_transaction) { @financial_transaction }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'

      should "include supplier" do
        assert_select "financial-transaction>supplier>id", "#{@supplier.id}"
      end
    end

    context "with json requested" do
      setup do
        get :show, :id => @financial_transaction.id, :format => "json"
      end

      should_assign_to(:financial_transaction) { @financial_transaction }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'
      should "include supplier" do
        assert_match /financial_transaction\":.+supplier\":.+id\":#{@supplier.id}/, @response.body
      end
    end
  end

end
