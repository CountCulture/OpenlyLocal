require File.expand_path('../../test_helper', __FILE__)

class OnsSubjectTest < ActiveSupport::TestCase
  subject { @ons_subject }
  context "The OnsSubject class" do
    setup do
      @ons_subject = Factory(:ons_subject) 
    end
    should validate_presence_of :title 
    should validate_presence_of :ons_uid
    should validate_uniqueness_of :ons_uid
    should have_and_belong_to_many :dataset_families
  end 
end
