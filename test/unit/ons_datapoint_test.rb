require 'test_helper'

class OnsDatapointTest < ActiveSupport::TestCase
  subject { @ons_dataset_family }
  context "The OnsDatapoint class" do
    setup do
      @ons_dataset_family = Factory(:ons_datapoint)
    end
    should_validate_presence_of :value
    should_belong_to :ons_dataset_topic
    should_belong_to :ward
  end
end
