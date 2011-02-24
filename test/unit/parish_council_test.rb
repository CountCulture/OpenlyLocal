require 'test_helper'

class ParishCouncilTest < ActiveSupport::TestCase
  
  should validate_presence_of :title
  should validate_presence_of :os_id
  
  should have_db_column :title
  should have_db_column :website
  should have_db_column :os_id
  should have_db_column :council_id
  should have_db_column :wdtk_name
  should have_db_column :vat_number
  should have_db_column :normalised_title


  should 'mixin TitleNormaliser::Base module' do
    assert ParishCouncil.respond_to?(:normalise_title)
  end
      
end
