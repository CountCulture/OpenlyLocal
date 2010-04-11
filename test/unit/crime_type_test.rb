require 'test_helper'

class CrimeTypeTest < ActiveSupport::TestCase
  subject { @crime_type }
  
  context "The CrimeType class" do
    setup do
      @crime_type = Factory(:crime_type)
    end
    
    should_validate_presence_of :name, :uid
  end
end
