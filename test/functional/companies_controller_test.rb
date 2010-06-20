require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  def setup
    @company = Factory(:company)
    @supplier = Factory(:supplier, :payee => @company)
  end
  
  context "on GET to :show" do
    setup do
      get :show, :id => @company.id
    end

    should_assign_to(:company) { @company}
    should respond_with :success
    should render_template :show

    should "show company name in title" do
      assert_select "title", /#{@company.title}/
    end
    
    should 'list suppliers as organisation' do
      assert_select 'li .supplier_link', /#{@supplier.organisation.title}/
    end
    

  end  

  context "with xml requested" do
    setup do
      get :show, :id => @company.id, :format => "xml"
    end

    should_assign_to(:company) { @company }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/xml'
    should "include suppliers" do
      assert_select "supplying-relationships>supplying-relationship>id", "#{@supplier.id}"
    end
    
    should "include supplying organisations" do
      assert_select "supplying-relationships>supplying-relationship>organisation>id", "#{@supplier.organisation.id}"
    end
  end

  context "with json requested" do
    setup do
      get :show, :id => @company.id, :format => "json"
    end

    should_assign_to(:company) { @company }
    should respond_with :success
    should_render_without_layout
    should respond_with_content_type 'application/json'
    should "include supplying organisations" do
      assert_match /supplying_relationships\":.+id\":#{@supplier.id}/, @response.body
    end
  end

end
