require 'test_helper'

class PoliceForceTest < ActiveSupport::TestCase
  subject { @police_force }
  
  context "The PoliceForce class" do
    setup do
      @police_force = Factory(:police_force)
    end
    
    should_have_many :councils 
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    should_validate_presence_of :url
    should_validate_uniqueness_of :url
    
    should_have_db_column :wikipedia_url
    should_have_db_column :telephone
    should_have_db_column :address
  end
end
