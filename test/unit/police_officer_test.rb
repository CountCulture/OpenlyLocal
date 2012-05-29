require File.expand_path('../../test_helper', __FILE__)

class PoliceOfficerTest < ActiveSupport::TestCase
  subject { @police_officer }
  
  context "The PoliceOfficer class" do
    setup do
      @police_officer = Factory(:police_officer)
    end
    
    should belong_to :police_team
    should validate_presence_of :name
    should validate_presence_of :police_team_id
    
    [:rank, :biography, :active].each do |column|
      should have_db_column column
    end
    
    context "with active named scope" do
      setup do
        @inactive_police_officer = Factory(:inactive_police_officer)
      end
      
      should "return only active officers" do
        assert_equal [@police_officer], PoliceOfficer.active
      end
    end
  end
  
  context "A PoliceTeam instance" do
    setup do
      @police_officer = Factory(:police_officer, :rank => "PC", :name => "Fred Flintsone")
      raw_bio = "\"Since the merger of the Abbey neighbourhood in January 2010, I provide high visibility reassurance patrols both on foot and on push bike, to reduce local crime and anti-social behaviour.\n\n\"I attend numerous neighbourhood watch meetings and hold surgeries within the community where anybody can attend and discuss any problems or issues they may have with myself.\n\n\"I also provide burglary victims with crime prevention advice and work alongside many partner agencies to tackle all the issues that concern the residents as well as the commercial side to the beat.\""
      @police_officer.biography = raw_bio
    end
    
    should "return rank and name as title" do
      assert_equal "PC Fred Flintsone", @police_officer.title
    end
    
    context "when setting biography" do
      should "remove double line spaces" do
        assert_match /behaviour\.\n/m, @police_officer[:biography] # only 1
        assert_no_match /behaviour\.\n\n/m, @police_officer[:biography] #... not 2
      end
      
      should "not raise exception if nil" do
        assert_nothing_raised(Exception) { @police_officer.biography = nil }
      end
      
      should "remove double quotes" do
        assert_match /^Since the/, @police_officer[:biography]
        assert_match /\nI attend/m, @police_officer[:biography]
      end
    end
  end
end
