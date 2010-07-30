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
    should have_many :suppliers
    should_have_many :financial_transactions, :through => :suppliers
    should have_one :police_authority 
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    should_validate_presence_of :url
    should_validate_uniqueness_of :url
    
    should have_db_column :wikipedia_url
    should have_db_column :telephone
    should have_db_column :address
    should have_db_column :wdtk_name
    should have_db_column :npia_id
    should have_db_column :facebook_account_name
    should have_db_column :youtube_account_name
    should have_db_column :feed_url
    should have_db_column :crime_map
    
    should "include TwitterAccountMethods mixin" do
      assert @police_force.respond_to?(:twitter_account_name)
    end
    
    should "include SocialNetworkingUtilities::Base mixin" do
      assert @police_force.respond_to?(:update_social_networking_details)
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
  end
   
end
