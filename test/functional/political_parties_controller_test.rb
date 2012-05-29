require File.expand_path('../../test_helper', __FILE__)

class PoliticalPartiesControllerTest < ActionController::TestCase
  def setup
    @political_party = Factory(:political_party)
  end
  
  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        stub_authentication
        get :index
      end

      should assign_to(:political_parties) { PoliticalParty.all}
      should respond_with :success
      should render_template :index
      should "list political parties" do
        assert_select "li", /#{@political_party.name}/
      end

      should 'show title' do
        assert_select "title", /political parties/i
      end
      
    end
  end
  # edit test
  context "on GET to :edit without auth" do
    setup do
      get :edit, :id => @political_party
    end
  
    should respond_with 401
  end
  
  context "on GET to :edit with existing record" do
    setup do
      stub_authentication
      get :edit, :id => @political_party
    end
  
    should assign_to(:political_party)
    should respond_with :success
    should render_template :edit
  
    should "show form" do
      assert_select "form#edit_political_party_#{@political_party.id}"
    end
  end  
  
  # update test
  context "on PUT to :update" do
    context "without auth" do
      setup do
        put :update, :id => @political_party.id, :political_party => { :name => "New Name", :url => "http://new.name.com"}
      end

      should respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @political_party.id, :political_party => { :name => "New Name", :url => "http://new.name.com"}
      end
    
      should_not_change("The number of political parties") { PoliticalParty.count }
      should_change( "The name of the political party", :to => "New Name") { @political_party.reload.name }
      should_change( "The url of the political party", :to => "http://new.name.com") { @political_party.reload.url }
      should assign_to :political_party
      should_redirect_to( "the index page for political parties") { political_parties_path }
      should_set_the_flash_to "Successfully updated political party"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @political_party.id, :political_party => {:name => ""}
      end
    
      should_not_change("The number of political parties") { PoliticalParty.count }
      should_not_change("The name of the political party") { @political_party.reload.name }
      should assign_to :political_party
      should render_template :edit
      should_not set_the_flash
    end
  
  end
end
