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
    
  end
end
