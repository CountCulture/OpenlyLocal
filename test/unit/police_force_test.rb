require 'test_helper'

class PoliceForceTest < ActiveSupport::TestCase
  subject { @police_force }
  
  context "The PoliceForce class" do
    setup do
      @police_force = Factory(:police_force)
    end
    
    should_have_many :councils
    should_have_many :police_teams
    should_have_many :crime_areas
    should_have_one :police_authority 
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    should_validate_presence_of :url
    should_validate_uniqueness_of :url
    
    should_have_db_column :wikipedia_url
    should_have_db_column :telephone
    should_have_db_column :address
    should_have_db_column :wdtk_name
    should_have_db_column :npia_id
    should_have_db_column :facebook_account_name
    should_have_db_column :youtube_account_name
    should_have_db_column :feed_url
    should_have_db_column :crime_map
    
    should "include TwitterAccountMethods mixin" do
      assert Member.new.respond_to?(:twitter_account_name)
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
  end
  
end
