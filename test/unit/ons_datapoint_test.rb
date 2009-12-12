require 'test_helper'

class OnsDatapointTest < ActiveSupport::TestCase
  subject { @ons_datapoint }
  context "The OnsDatapoint class" do
    setup do
      @ons_datapoint = Factory(:ons_datapoint)
    end

    should_validate_presence_of :value, :ons_dataset_topic_id, :ward_id
    should_belong_to :ons_dataset_topic
    should_belong_to :ward
    should "belong_to ons_dataset_family through ons_dataset_topic" do
      assert_equal @ons_datapoint.ons_dataset_topic.ons_dataset_family, @ons_datapoint.ons_dataset_family
    end
  end

  context "an OnsDatapoint instance" do
    setup do
      @ons_datapoint = Factory(:ons_datapoint)
      @ons_topic = @ons_datapoint.ons_dataset_topic
      @ward = @ons_datapoint.ward
    end

    should "include ward and topic id in title" do
      assert_equal "#{@ons_topic.title} (#{@ward.name})", @ons_datapoint.title
    end

    should "format value depending on muid" do
      assert_equal '345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => nil)).value
      assert_equal '345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 1)).value
      assert_equal '£345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 9)).value
      assert_equal '24.6%', OnsDatapoint.new(:value => '24.62', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 2)).value
    end
  end
end
