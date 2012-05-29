require File.expand_path('../../test_helper', __FILE__)

class PostcodeTest < ActiveSupport::TestCase
  subject { @postcode }
  
  def setup
    @postcode = Factory(:postcode, :code => 'AB13DR')
  end
  
  context "The Postcode class" do
    
    [:code, :lat, :lng].each do |attribute|
      should validate_presence_of attribute
    end
    should validate_uniqueness_of :code
    [:quality, :lat, :lng, :country, :nhs_region, :nhs_health_authority, :county_id, :council_id, :ward_id].each do |column|
      should have_db_column column
    end
    should belong_to :ward
    should belong_to :council
    should belong_to :county
    should belong_to :crime_area
    
    should "act as mappable" do
      assert Postcode.respond_to?(:find_closest)
    end
    
    context "when finding from messy code" do
      should 'find from  cleaned up code' do
        assert_equal @postcode, Postcode.find_from_messy_code(' ab 1 3Dr ')
      end

      should 'return nil if code blank' do
        assert_nil Postcode.find_from_messy_code(nil)
        assert_nil Postcode.find_from_messy_code('')
      end
    end
    
    should 'have many councillors through ward' do
      ward = Factory(:ward)
      @postcode.update_attribute(:ward_id, ward.id)
      another_ward = Factory(:ward, :name => 'another ward', :council => ward.council)
      member = Factory(:member, :ward => ward, :council => ward.council)
      another_member = Factory(:member, :ward => another_ward, :council => ward.council)
      assert_equal [member], @postcode.councillors
    end
    
    context 'when returning hyperlocal sites' do
      setup do
        @close_site = Factory(:approved_hyperlocal_site, :lat => @postcode.lat+0.05, :lng => @postcode.lng-0.05)
        @closest_site = Factory(:approved_hyperlocal_site, :lat => @postcode.lat+0.01, :lng => @postcode.lng-0.01)
        @unapproved_site = Factory(:hyperlocal_site, :lat => @postcode.lat+0.01, :lng => @postcode.lng+0.01)
        @faraway_site = Factory(:approved_hyperlocal_site, :lat => @postcode.lat+10.0, :lng => @postcode.lng-10.0)
      end
      
      should 'return sites close to postcode' do
        assert @postcode.hyperlocal_sites.include?(@close_site)
      end
      
      should 'not return faraway site' do
        assert !@postcode.hyperlocal_sites.include?(@faraway_site)
      end
      
      should 'return only approved sites' do
        assert !@postcode.hyperlocal_sites.include?(@unapproved_site)
      end
      
      should 'return closest first' do
        assert_equal @closest_site, @postcode.hyperlocal_sites.first
      end
      
    end
  end
  
  context 'an instance of the Postcode class' do
    should 'return pretty code' do
      assert_equal 'AB1D 3DL', Postcode.new(:code => 'AB1D3DL').pretty_code
    end
  end
end
