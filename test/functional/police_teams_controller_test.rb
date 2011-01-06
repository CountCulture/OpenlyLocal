require 'test_helper'

class PoliceTeamsControllerTest < ActionController::TestCase
  def setup
    @police_team = Factory(:police_team)
    @police_officer = Factory(:police_officer, :police_team => @police_team)
    @inactive_police_officer = Factory(:inactive_police_officer, :police_team => @police_team)
    @ward = Factory(:ward, :police_team => @police_team)
  end
  
  # show test
  context "on GET to :show" do
    setup do
      get :show, :id => @police_team.id
    end
  
    should assign_to(:police_team) { @police_team}
    should respond_with :success
    should render_template :show
    should_render_with_layout
  
    should "show police_team in title" do
      assert_select "title", /#{@police_team.name}/
    end
    
    should 'show associated police_force' do
      assert_select ".attributes a", @police_team.police_force.name
    end
    
    should 'show associated wards' do
      assert_select ".attributes a", @ward.title
    end
        
    should 'show associated wards' do
      assert_select ".attributes a", @police_team.police_force.name
    end
    
    should 'show associated police_officers' do
      assert_select "#police_officers li", /#{@police_officer.name}/
    end
    
    should 'not show associated inactive police_officers' do
      assert_select "#police_officers li", :text => /#{@inactive_police_officer.name}/, :count => 0
    end
    
    should "show share block" do
      assert_select "#share_block"
    end
    
  end  
end
