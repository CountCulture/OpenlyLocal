require 'test_helper'

class ElectionTest < ActiveSupport::TestCase
  subject { @election }

  context "The Election class" do
    setup do
      @election = Factory(:election)
    end
    should_belong_to :ward
    should_validate_presence_of :date
    should_validate_presence_of :ward_id
    should_validate_presence_of :ward_id
    should_have_db_columns :electorate
  end

  context "An Election instance" do
    setup do
      @election = Factory(:election)
    end
  end
end
