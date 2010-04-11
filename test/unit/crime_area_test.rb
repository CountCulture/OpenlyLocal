require 'test_helper'

class CrimeAreaTest < ActiveSupport::TestCase
  subject { @crime_area }
  
  context "The CrimeArea class" do
    setup do
      @crime_area = Factory(:crime_area)
    end
    
    should_belong_to :police_force
    should_validate_presence_of :name, :uid, :police_force_id, :level
    should_validate_uniqueness_of :uid, :scoped_to => :police_force_id
    should_have_db_columns :crime_mapper_url, :feed_url, :crime_level_cf_national, :crime_rates, :total_crimes
    
    should 'serialize crime_rates' do
      crime_rates = [{:foo => 'bar'}]
      assert_equal crime_rates, Factory(:crime_area, :crime_rates => crime_rates).reload.crime_rates
    end
    
    should 'serialize total_crimes' do
      total_crimes = [{:foo => 'bar'}]
      assert_equal total_crimes, Factory(:crime_area, :total_crimes => total_crimes).reload.total_crimes
    end
  end
end
