require 'test_helper'

class PoliticalPartiesControllerTest < ActionController::TestCase
  def setup
    @political_party = Factory(:political_party)
  end
  
  # edit test
  context "on GET to :edit without auth" do
    setup do
      get :edit, :id => @political_party
    end
  
    should_respond_with 401
  end
  
  context "on GET to :edit with existing record" do
    setup do
      stub_authentication
      get :edit, :id => @political_party
    end
  
    should_assign_to(:political_party)
    should_respond_with :success
    should_render_template :edit
  
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

      should_respond_with 401
    end
    
    context "with valid params" do
      setup do
        stub_authentication
        put :update, :id => @political_party.id, :political_party => { :name => "New Name", :url => "http://new.name.com"}
      end
    
      should_not_change "PoliceForce.count"
      should_change "@political_party.reload.name", :to => "New Name"
      should_change "@political_party.reload.url", :to => "http://new.name.com"
      should_assign_to :political_party
      should_redirect_to( "the show page for political party") { political_party_path(assigns(:political_party)) }
      should_set_the_flash_to "Successfully updated political party"
    
    end
    
    context "with invalid params" do
      setup do
        stub_authentication
        put :update, :id => @political_party.id, :political_party => {:name => ""}
      end
    
      should_not_change "PoliceForce.count"
      should_not_change "@political_party.reload.name"
      should_assign_to :political_party
      should_render_template :edit
      should_not_set_the_flash
    end
  
  end
end
