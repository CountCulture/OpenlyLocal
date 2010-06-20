require 'test_helper'

class SuppliersControllerTest < ActionController::TestCase
  def setup
    @supplier = Factory(:supplier)
    @organisation = @supplier.organisation
    @another_supplier = Factory(:supplier, :name => 'A supplier')
    @another_supplier_same_org = Factory(:supplier, :name => 'Another supplier', :organisation => @organisation)
    @financial_transaction = Factory(:financial_transaction, :supplier => @supplier, :value => 42)
  end
  
  # index test
  context "on GET to :index" do
    
    context "with basic request" do
      setup do
        get :index
      end
      
      should_assign_to(:suppliers)
      should respond_with :success
      
      should "show title" do
        assert_select "title", /suppliers/i
      end
      
      should 'list suppliers' do
        assert_select 'a.supplier_link', @supplier.name
      end
      
      should 'order by name' do
        assert_equal @another_supplier, assigns(:suppliers).first
      end
      
      should 'show link to sort by total_spend' do
        assert_select 'a.sort', /total spend/i
      end
            
    end
    
    context 'when sorting by total_spend' do
      setup do
        get :index, :order => 'total_spend'
      end
      
      should_assign_to(:suppliers)
      should respond_with :success
      
      
      should 'order by total_spend' do
        assert_equal @supplier, assigns(:suppliers).first
      end
            
      should 'show link to sort by name' do
        assert_select 'a.sort', /name/i
      end
            
    end
    
    context 'when enough results' do
      setup do
        30.times { Factory(:supplier) }
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
      
      context "with xml requested" do
        setup do
          get :index, :format => "xml"
        end

        should assign_to(:suppliers)
        should respond_with :success
        should_render_without_layout
        should respond_with_content_type 'application/xml'

        should "include suppliers" do
          assert_select "suppliers>supplier>id"
        end

        should_eventually "include organisation" do
          assert_select "suppliers>supplier>organisation>id"
        end

        should 'include pagination info' do
          assert_select "suppliers>total-entries"
        end
      end
      
      context "with json requested" do
        setup do
          get :index, :format => "json"
        end

        should assign_to(:suppliers)
        should respond_with :success
        should_render_without_layout
        should respond_with_content_type 'application/json'
        
        should 'include pagination info' do
          assert_match %r(total_entries.+33), @response.body
          assert_match %r(per_page), @response.body
          assert_match %r(page.+1), @response.body
        end
      end
      
    end
    
    context "with basic request and organisation details" do
      setup do
        
      end
      context "in general" do
        setup do
          get :index, :organisation_id => @organisation.id, :organisation_type => @organisation.class.to_s
        end

        should_assign_to(:suppliers)
        should_assign_to(:organisation) { @organisation }
        should respond_with :success

        should "show title" do
          assert_select "title", /suppliers/i
        end

        should 'list suppliers' do
          assert_select 'a.supplier_link', @supplier.name
        end
        
        should 'order by name' do
          assert_equal @another_supplier_same_org, assigns(:suppliers).first
        end

        should 'show link to sort by total_spend' do
          assert_select 'a.sort', /total spend/i
        end
        
        should 'show overview of spending' do
          assert_select '#overview', /suppliers/i
        end
      end
      
      context 'when sorting by total_spend' do
        setup do
          get :index, :organisation_id => @organisation.id, :organisation_type => @organisation.class.to_s, :order => 'total_spend'
        end

        should_assign_to(:suppliers)
        should respond_with :success


        should 'order by total_spend' do
          assert_equal @supplier, assigns(:suppliers).first
        end

        should 'show link to sort by name' do
          assert_select 'a.sort', /name/i
        end

      end
         
    end    
    
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
      @company = Factory(:company)
      @supplier.update_attribute(:payee, @company)
      get :show, :id => @supplier.id, :format => "xml"
    end

    should_assign_to(:supplier) { @supplier }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/xml'
    should "include company" do
      assert_select "supplier>payee>id", "#{@company.id}"
    end
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
