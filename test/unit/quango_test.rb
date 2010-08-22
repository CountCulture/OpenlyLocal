require 'test_helper'

class QuangoTest < ActiveSupport::TestCase
  context "The Quango class" do
    setup do
      @quango = Factory(:quango)
    end
    
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
