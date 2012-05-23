require File.expand_path('../../test_helper', __FILE__)

class CrimeTypeTest < ActiveSupport::TestCase
  subject { @crime_type }
  
  context "The CrimeType class" do
    setup do
      @crime_type = Factory(:crime_type)
    end
    
    [:name, :uid].each do |attribute|
      should validate_presence_of attribute
    end
  end
end
