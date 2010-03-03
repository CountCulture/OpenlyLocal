require 'test_helper'

class PoliceTeamTest < ActiveSupport::TestCase
  subject { @police_team }
  
  context "The PoliceTeam class" do
    setup do
      @police_team = Factory(:police_team)
    end
    
    should_belong_to :police_force
    should_validate_presence_of :uid
    should_validate_presence_of :name
    should_validate_presence_of :police_force_id
    
    should_have_db_columns :url, :description, :lat, :lng    
  end
  
  context "A PoliceTeam instance" do
    setup do
      @police_team = Factory(:police_team)
    end
    
    should "alias name as title" do
      assert_equal @police_team.name, @police_team.title
    end

    should "use title in to_param method" do
      @police_team.name = "some title-with/stuff"
      assert_equal "#{@police_team.id}-some-title-with-stuff", @police_team.to_param
    end
    
    should "return force in extended title" do
      assert_match /#{@police_team.police_force.name}/, @police_team.extended_title
    end
  end
end
