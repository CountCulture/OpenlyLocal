require 'test_helper'

class PoliceAuthorityTest < ActiveSupport::TestCase
  subject { @police_authority }
  
  context "The PoliceAuthority class" do
    setup do
      @police_authority = Factory(:police_authority)
    end
    
    should_validate_presence_of :name
    should_validate_presence_of :police_force_id
    should_validate_uniqueness_of :name, :police_force_id
    should belong_to :police_force
    should have_many :councils#, :through => :police_force
    should have_many :supplying_relationships
    
    should have_db_column :url
    should have_db_column :wikipedia_url
    should have_db_column :telephone
    should have_db_column :address
    should have_db_column :wdtk_name
    should have_db_column :annual_audit_letter
    should have_db_column :vat_number
        
  end
  
  context "A PoliceAuthority instance" do
    setup do
      @police_authority = Factory(:police_authority)
    end
    
    should "alias name as title" do
      assert_equal @police_authority.name, @police_authority.title
    end

    should "use title in to_param method" do
      @police_authority.name = "some title-with/stuff"
      assert_equal "#{@police_authority.id}-some-title-with-stuff", @police_authority.to_param
    end
    
    context "when returning dbpedia_resource" do

      should "return nil if wikipedia_url blank" do
        assert_nil @police_authority.dbpedia_resource
      end

      should "return dbpedia url" do
        @police_authority.wikipedia_url = "http://en.wikipedia.org/wiki/Herefordshire_Police"
        assert_equal "http://dbpedia.org/resource/Herefordshire_Police", @police_authority.dbpedia_resource
      end
    end

    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @police_authority.foaf_telephone
      end

      should "return formatted number" do
        @police_authority.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @police_authority.foaf_telephone
      end
    end
  end
end
