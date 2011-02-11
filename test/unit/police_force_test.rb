require 'test_helper'

class PoliceForceTest < ActiveSupport::TestCase
  subject { @police_force }
  
  context "The PoliceForce class" do
    setup do
      @police_force = Factory(:police_force)
    end
    
    should have_many :councils
    should have_many :police_teams
    should have_many :crime_areas
    should have_one :police_authority 
    should validate_presence_of :name
    should validate_uniqueness_of :name
    should validate_presence_of :url
    should validate_uniqueness_of :url
    
    should have_db_column :wikipedia_url
    should have_db_column :telephone
    should have_db_column :address
    should have_db_column :wdtk_name
    should have_db_column :npia_id
    should have_db_column :facebook_account_name
    should have_db_column :youtube_account_name
    should have_db_column :feed_url
    should have_db_column :crime_map
    should have_db_column :wdtk_id
    
    should "include TwitterAccountMethods mixin" do
      assert @police_force.respond_to?(:twitter_account_name)
    end
    
    should "include SocialNetworkingUtilities::Base mixin" do
      assert @police_force.respond_to?(:update_social_networking_details)
    end
    
    should "mixin SpendingStat::Base module" do
      assert @police_force.respond_to?(:spending_stat)
    end
    
    should "mixin SpendingStatUtilities::Payee module" do
      assert PoliceForce.new.respond_to?(:supplying_relationships)
    end

    
    should 'have one force_crime_area' do
      non_force_crime_area = Factory(:crime_area, :police_force => @police_force, :level => 3)
      force_crime_area = Factory(:crime_area, :police_force => @police_force, :level => 1)
      unrelated_force_crime_area = Factory(:crime_area, :level => 1)
      assert_equal force_crime_area, @police_force.force_crime_area
    end
  end
  
  context "A PoliceForce instance" do
    setup do
      @police_force = Factory(:police_force)
    end
    
    should "alias name as title" do
      assert_equal @police_force.name, @police_force.title
    end

    should "use title in to_param method" do
      @police_force.name = "some title-with/stuff"
      assert_equal "#{@police_force.id}-some-title-with-stuff", @police_force.to_param
    end
    
    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/police_forces/#{@police_force.id}", @police_force.resource_uri
    end
    
    context "when returning dbpedia_resource" do

      should "return nil if wikipedia_url blank" do
        assert_nil @police_force.dbpedia_resource
      end

      should "return dbpedia url" do
        @police_force.wikipedia_url = "http://en.wikipedia.org/wiki/Herefordshire_Police"
        assert_equal "http://dbpedia.org/resource/Herefordshire_Police", @police_force.dbpedia_resource
      end
    end

    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @police_force.foaf_telephone
      end

      should "return formatted number" do
        @police_force.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @police_force.foaf_telephone
      end
    end
  
    should 'return correct url as openlylocal_url' do
      assert_equal "http://#{DefaultDomain}/police_forces/#{@police_force.to_param}", @police_force.openlylocal_url
    end
    
    context "when updating police_teams" do
      setup do
        dummy_response = { "team"=> [ {"name"=>"Cotham", "id"=>"BC173"}, 
                                      {"name"=>"Redland", "id"=>"BC174"}, 
                                      {"name"=>"Bishopston", "id"=>"BC175"}, 
                                      {"name"=>"Kingsdown", "id"=>"BC190"} ]
                                    }
        
        NpiaUtilities::Client.any_instance.stubs(:response).returns(dummy_response)
      end

      should "make call to NPIA api" do
        NpiaUtilities::Client.expects(:new).with(:teams, :force => @police_force.npia_id).returns(stub_everything)
        @police_force.update_teams
      end

      should "create teams for force" do
        assert_difference 'PoliceTeam.count', 4 do
          @police_force.update_teams
        end
      end

      should "update existing teams" do
        existing_team = Factory(:police_team, :police_force => @police_force, :name => 'Foo Team', :uid => 'BC174')
        assert_difference 'PoliceTeam.count', 3 do
          @police_force.update_teams
        end
        assert_equal 'Redland', existing_team.reload.name
      end

      should "mark orphan teams as defunkt" do
        orphan_team = Factory(:police_team, :police_force => @police_force, :name => 'Foo Team', :uid => 'BC170')
        @police_force.update_teams
        assert orphan_team.reload.defunkt?
      end

      should "not raise error if no teams found for force" do
        NpiaUtilities::Client.any_instance.expects(:response).returns('team' => [])
        assert_nothing_raised(Exception) { @police_force.update_teams }
      end

      should "return all teams for force" do
        assert_kind_of Array, teams = @police_force.update_teams
        assert_equal 4, teams.size
        assert_kind_of PoliceTeam, teams.first
      end
    end
  end
   
end
