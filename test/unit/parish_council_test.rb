require 'test_helper'

class ParishCouncilTest < ActiveSupport::TestCase
  
  should validate_presence_of :title
  should validate_presence_of :os_id
  
  should have_db_column :title
  should have_db_column :website
  should have_db_column :os_id
  should have_db_column :council_id
  should have_db_column :gss_code
  should have_db_column :wdtk_name
  should have_db_column :vat_number
  should have_db_column :normalised_title
  should belong_to :council


  should 'mixin TitleNormaliser::Base module' do
    assert ParishCouncil.respond_to?(:normalise_title)
  end
  
  should "mixin SpendingStatUtilities::Base module" do
    assert ParishCouncil.new.respond_to?(:spending_stat)
  end
  
  should "mixin SpendingStatUtilities::Payee module" do
    assert ParishCouncil.new.respond_to?(:supplying_relationships)
  end

      
end
