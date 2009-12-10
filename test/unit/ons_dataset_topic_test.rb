require 'test_helper'

class OnsDatasetTopicTest < ActiveSupport::TestCase
  subject { @ons_dataset_family }
  context "The OnsDatasetTopic class" do
    setup do
      @ons_dataset_family = Factory(:ons_dataset_topic)
    end
    should_validate_presence_of :title
    should_validate_presence_of :ons_uid
    should_validate_presence_of :ons_dataset_family_id
    should_belong_to :ons_dataset_family
  end
end
