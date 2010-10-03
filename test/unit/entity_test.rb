require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  context "The Entity class" do
    setup do
      @entity = Factory(:entity)
    end
    should have_many :supplying_relationships
    should have_many :suppliers
    should_have_many :financial_transactions, :through => :suppliers
    
    should "mixin SpendingStat::Base module" do
      assert Entity.new.respond_to?(:spending_stat)
    end
    
    should 'mixin AddressMethods module' do
      assert @entity.respond_to?(:address_in_full)
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
    
  end
end
