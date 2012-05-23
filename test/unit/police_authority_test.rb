require File.expand_path('../../test_helper', __FILE__)

class PoliceAuthorityTest < ActiveSupport::TestCase
  subject { @police_authority }
  
  context "The PoliceAuthority class" do
    setup do
      @police_authority = Factory(:police_authority)
    end
    
    should validate_presence_of :name
    should validate_presence_of :police_force_id
    [:name, :police_force_id].each do |attribute|
      should validate_uniqueness_of attribute
    end
    should belong_to :police_force
    should have_many(:councils).through :police_force

    [ :url, :wikipedia_url, :telephone, :address, :wdtk_name,
      :annual_audit_letter, :vat_number, :wdtk_id,
    ].each do |column|
      should have_db_column column
    end
        
    should "mixin SpendingStat::Base module" do
      assert PoliceAuthority.new.respond_to?(:spending_stat)
    end

    should "mixin SpendingStatUtilities::Payee module" do
      assert PoliceAuthority.new.respond_to?(:supplying_relationships)
    end

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
    
    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/police_authorities/#{@police_authority.id}", @police_authority.resource_uri
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
