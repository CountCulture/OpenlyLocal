require 'test_helper'

class OfficerTest < ActiveSupport::TestCase
  subject { @officer }
  
  context "The Officer class" do
    setup do
      @officer = Factory(:officer)
    end
    
    should_belong_to :council 
    should_validate_presence_of :last_name
    should_validate_presence_of :position
    should_validate_presence_of :council_id
  end
end
