require File.expand_path('../../test_helper', __FILE__)

class PoliceTeamTest < ActiveSupport::TestCase
  subject { @police_team }
  
  context "The PoliceTeam class" do
    setup do
      @police_team = Factory(:police_team)
      @police_force = @police_team.police_force
      @defunkt_police_team = Factory(:police_team, :defunkt => true)
    end
    
    should belong_to :police_force
    should have_many :police_officers
    should have_many :wards
    should validate_presence_of :uid
    should validate_presence_of :name
    should validate_presence_of :police_force_id
    
    [:url, :description, :lat, :lng].each do |column|
      should have_db_column column
    end
    
    context 'should have defunkt named scope which' do
      
      should 'return defunkt teams only' do
        defunkt_teams = PoliceTeam.defunkt
        assert !defunkt_teams.include?(@police_team)
        assert defunkt_teams.include?(@defunkt_police_team)
      end
      
    end
    
    context 'should have current named scope and' do
      
      should 'return current wards only' do
        current_teams = PoliceTeam.current
        assert current_teams.include?(@police_team)
        assert !current_teams.include?(@defunkt_police_team)
      end
      
    end
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
    
  context "when updating officers" do
    setup do
      dummy_response = {'person' => [ {"name"=>"Steven Mildren", "rank"=>"Inspector", "bio"=>nil},
                                      {"name"=>"Richard Durnford", "rank"=>"Sergeant", "bio"=>nil},
                                      {"name"=>"Andrew Grabowski", "rank"=>"Constable", "bio"=>"\"Since the merger of the Abbey neighbourhood in January 2010, I provide high visibility reassurance patrols both on foot and on push bike, to reduce local crime and anti-social behaviour.\n\n\"I attend numerous neighbourhood watch meetings and hold surgeries within the community where anybody can attend and discuss any problems or issues they may have with myself.\n\n\"I also provide burglary victims with crime prevention advice and work alongside many partner agencies to tackle all the issues that concern the residents as well as the commercial side to the beat.\""},
                                      {"name"=>"Kelly Norris", "rank"=>"Constable", "bio"=>"I have been based at Beaumont Leys since becoming a PCSO in 2003.\n\nI have developed strong links with the community and partner agencies and use these links to assist with solving issues on the beat area.\n\n"}] }
      NpiaUtilities::Client.any_instance.stubs(:response).returns(dummy_response)
    end
    
    should "make call to NPIA api" do
      NpiaUtilities::Client.expects(:new).with(:team_people, :force => @police_team.police_force.npia_id, :team => @police_team.uid).returns(stub_everything)
      @police_team.update_officers
    end
    
    should "create officers for force" do
      assert_difference 'PoliceOfficer.count', 4 do
        @police_team.update_officers
      end
    end
    
    should "update existing officers" do
      existing_officer = Factory(:police_officer, :police_team => @police_team, :name => 'Kelly Norris', :rank => 'Constable', :biography => 'hello world')
      assert_difference 'PoliceOfficer.count', 3 do
        @police_team.update_officers
      end
      assert_match /I have been based/, existing_officer.reload.biography
    end
    
    should "mark orphan officers as inactive" do
      @orphan_officer = Factory(:police_officer, :police_team => @police_team, :name => 'Percy Plod')
      @police_team.update_officers
      assert !@orphan_officer.reload.active
    end
    
    should "not raise error if no officers found for area" do
      NpiaUtilities::Client.any_instance.expects(:response).returns('person' => [])
      assert_nothing_raised(Exception) { @police_team.update_officers }
    end
    
    should "not raise error if only one officer found for area" do
      NpiaUtilities::Client.any_instance.expects(:response).returns('person' => {"name"=>"Steven Mildren", "rank"=>"Inspector", "bio"=> nil })
      assert_nothing_raised(Exception) { @police_team.update_officers }
    end
    
    should "return all officers for team" do
      assert_kind_of Array, officers = @police_team.update_officers
      assert_equal 4, officers.size
      assert_kind_of PoliceOfficer, officers.first
    end
  end

  end
end
