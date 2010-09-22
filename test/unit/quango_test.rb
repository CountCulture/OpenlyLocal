require 'test_helper'

class QuangoTest < ActiveSupport::TestCase
  context "The Quango class" do
    setup do
      @quango = Factory(:quango)
    end
    should have_many :supplying_relationships
    
    should "mixin SpendingStat::Base module" do
      assert Quango.new.respond_to?(:spending_stat)
    end
    
    should 'mixin AddressMethods module' do
      assert @quango.respond_to?(:address_in_full)
    end
        
    should validate_presence_of :title
    
    should have_db_column :title
    should have_db_column :quango_type
    should have_db_column :quango_subtype
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
