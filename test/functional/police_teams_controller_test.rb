require 'test_helper'

class PoliceTeamsControllerTest < ActionController::TestCase
  def setup
    @police_team = Factory(:police_team)
  end
  
  # show test
  context "on GET to :show" do
    setup do
      get :show, :id => @police_team.id
    end
  
    should_assign_to(:police_team) { @police_team}
    should_respond_with :success
    should_render_template :show
    should_render_with_layout
  
    should "show police_team in title" do
      assert_select "title", /#{@police_team.name}/
    end
    
    should 'show associated police_force' do
      assert_select ".attributes a", @police_team.police_force.name
    end
    
    should "show share block" do
      assert_select "#share_block"
    end
    
  end  
end
