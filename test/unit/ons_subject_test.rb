require 'test_helper'

class OnsSubjectTest < ActiveSupport::TestCase
  subject { @ons_subject }
  context "The OnsSubject class" do
    setup do
      @ons_subject = Factory(:ons_subject) 
    end
    should_validate_presence_of :title 
    should_validate_presence_of :ons_uid
    should_validate_uniqueness_of :ons_uid
    should_have_and_belong_to_many :ons_dataset_families
  end 
end
