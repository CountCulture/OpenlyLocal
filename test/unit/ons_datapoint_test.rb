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

    should "restrict to given ness topic ids" do
      @ward = @ons_datapoint.ward
      ons_datapoint_1 = Factory(:ons_datapoint, :ward => @ward)
      ons_datapoint_2 = Factory(:ons_datapoint, :ward => @ward)
      ons_datapoint_3 = Factory(:ons_datapoint, :ward => @ward)
      topic_uids = [ ons_datapoint_2.ons_dataset_topic.ons_uid,
                     ons_datapoint_3.ons_dataset_topic.ons_uid]
      assert_equal [ons_datapoint_2, ons_datapoint_3], OnsDatapoint.with_topic_uids(topic_uids)
    end
  end

  context "an OnsDatapoint instance" do
    setup do
      @ons_datapoint = Factory(:ons_datapoint)
      @ons_dataset_topic = @ons_datapoint.ons_dataset_topic
      @ward = @ons_datapoint.ward
    end

    should "include ward and topic id in title" do
      assert_equal "#{@ons_dataset_topic.title} (#{@ward.name})", @ons_datapoint.title
    end

    should "format value depending on muid" do
      assert_equal '345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => nil)).value
      assert_equal '345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 1)).value
      assert_equal '£345', OnsDatapoint.new(:value => '345', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 9)).value
      assert_equal '24.6%', OnsDatapoint.new(:value => '24.62', :ons_dataset_topic => Factory(:ons_dataset_topic, :muid => 2)).value
    end

    context "when returning related datapoints" do
      setup do
        @sibling_ward = Factory(:ward, :name => 'sibling ward', :council => @ward.council)
        @unrelated_ward = Factory(:ward, :name => 'unrelated ward', :council => Factory(:another_council))
        @same_topic_sibling_ward_dp = Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :ward => @sibling_ward)
        @same_topic_unrelated_ward_dp = Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :ward => @unrelated_ward)
        @different_topic_and_sibling_ward_dp = Factory(:ons_datapoint, :ward => @sibling_ward)
      end

      should "return only datapoints for same topic from sibling wards" do
        assert_equal [@same_topic_sibling_ward_dp], @ons_datapoint.related_datapoints
      end
    end
  end
end
