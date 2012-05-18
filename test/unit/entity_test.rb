require File.expand_path('../../test_helper', __FILE__)

class EntityTest < ActiveSupport::TestCase
  context "The Entity class" do
    setup do
      @entity = Factory(:entity)
    end
    
    should "mixin SpendingStatUtilities::Base module" do
      assert Entity.new.respond_to?(:spending_stat)
    end
    
    should "mixin SpendingStatUtilities::Payee module" do
      assert Entity.new.respond_to?(:supplying_relationships)
    end

    should "mixin SpendingStatUtilities::Payer module" do
      assert Entity.new.respond_to?(:payments)
    end
    
    should 'mixin AddressUtilities::Base module' do
      assert @entity.respond_to?(:address_in_full)
    end
        
    should 'mixin TitleNormaliser::Base module' do
      assert Entity.respond_to?(:normalise_title)
    end
        
    should validate_presence_of :title
    
    should have_db_column :title
    should have_db_column :entity_type
    should have_db_column :entity_subtype
    should have_db_column :website
    should have_db_column :wikipedia_url
    should have_db_column :previous_names
    should have_db_column :sponsoring_organisation
    should have_db_column :setup_on
    should have_db_column :disbanded_on
    should have_db_column :wdtk_name
    should have_db_column :vat_number
    should have_db_column :cpid_code
    should have_db_column :normalised_title
    should have_db_column :external_resource_uri
    should have_db_column :other_attributes
    
    should 'serialize other attributes' do
      assert_equal %w(foo bar), Factory(:entity, :other_attributes => %w(foo bar)).reload.other_attributes
    end
    
    context "when normalising title" do
      should "normalise title" do
        TitleNormaliser.expects(:normalise_title).with('foo bar')
        Entity.normalise_title('foo bar')
      end
    end
    
    should 'return correct url as openlylocal_url' do
      assert_equal "http://#{DefaultDomain}/entities/#{@entity.to_param}", @entity.openlylocal_url
    end
    
    should "include ResourceMethods" do
      assert Entity.new.respond_to? :foaf_telephone
    end
    
    should "alias website as url" do
      assert_equal 'http://foo.com', Entity.new(:website => 'http://foo.com').url
      assert_equal 'http://foo.com', Entity.new(:url => 'http://foo.com').website
    end
    
  end
  
  context "an instance of the Entity class" do
    setup do
      @entity = Factory(:entity)
    end

    context "when saving" do
      should "normalise title" do
        @entity.expects(:normalise_title)
        @entity.save!
      end
  
      should "save normalised title" do
        @entity.title = "Foo & Baz Dept"
        @entity.save!
        assert_equal "foo and baz dept", @entity.reload.normalised_title
      end
    end

    context "when returning resource_uri" do
      should 'build resource uri using DefaultDomain and id' do
        assert_equal "http://#{DefaultDomain}/id/entities/#{@entity.id}", @entity.resource_uri
      end
    end    
    
  end
end
