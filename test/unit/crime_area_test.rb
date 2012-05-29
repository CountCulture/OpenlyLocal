require File.expand_path('../../test_helper', __FILE__)

class CrimeAreaTest < ActiveSupport::TestCase
  subject { @crime_area }
  
  context "The CrimeArea class" do
    setup do
      @crime_area = Factory(:crime_area)
    end
    
    should belong_to :police_force
    [:name, :uid, :police_force_id, :level].each do |attribute|
      should validate_presence_of attribute
    end
    should validate_uniqueness_of(:uid).scoped_to :police_force_id
    [:crime_mapper_url, :feed_url, :crime_level_cf_national, :crime_rates, :total_crimes].each do |column|
      should have_db_column column
    end
    
    should 'serialize crime_rates' do
      crime_rates = [{:foo => 'bar'}]
      assert_equal crime_rates, Factory(:crime_area, :crime_rates => crime_rates).reload.crime_rates
    end
    
    should 'serialize total_crimes' do
      total_crimes = [{:foo => 'bar'}]
      assert_equal total_crimes, Factory(:crime_area, :total_crimes => total_crimes).reload.total_crimes
    end
  end
  
  context 'an instance of the CrimeArea class' do
    setup do
      @crime_area = Factory(:crime_area)
    end

    context 'when returning crime_rate_comparison' do
      setup do
        @local_crime_rate_data = [{"date"=>"2008-12", "value"=>"42.2"}, {"date"=>"2009-01", "value"=>"51"}, {"date"=>"2009-02", "value"=>"3.1"}]
        @crime_area.update_attribute(:crime_rates, @local_crime_rate_data)
        @police_force = @crime_area.police_force
      end
      
      should 'return nil if no crime_rate info for area' do
        assert_nil CrimeArea.new.crime_rate_comparison
        @crime_area.update_attribute(:crime_rates, [])
        assert_nil @crime_area.crime_rate_comparison
      end
      
      should 'return crime_rate array by default' do
        assert_equal @local_crime_rate_data, @crime_area.crime_rate_comparison
      end
      
      context 'and force has crime_rate area' do
        setup do
          @police_force_crime_area = Factory(:crime_area, :police_force => @police_force, :level => 1, 
                                             :crime_rates => [{"date"=>"2009-01", "value"=>"2.5"}, {"date"=>"2009-04", "value"=>"6"}])
        end
        
        should 'return force data as force_value matched to dates' do
          expected_result = [{'date'=>"2008-12", "value"=>"42.2"}, {'date'=>"2009-01", "value"=>"51", 'force_value' => '2.5'}, {'date'=>"2009-02", "value"=>"3.1"}]
          assert_equal expected_result, @crime_area.crime_rate_comparison
        end
        
      end
    end
  end
end
