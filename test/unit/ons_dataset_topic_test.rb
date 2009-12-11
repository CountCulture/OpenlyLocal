require 'test_helper'

class OnsDatasetTopicTest < ActiveSupport::TestCase
  subject { @ons_dataset_topic }
  context "The OnsDatasetTopic class" do
    setup do
      @ons_dataset_topic = Factory(:ons_dataset_topic)
    end
    should_validate_presence_of :title
    should_validate_presence_of :ons_uid
    should_validate_presence_of :ons_dataset_family_id
    should_belong_to :ons_dataset_family
    should_have_db_column :muid
  end

  context "An OnsDatasetTopic instance" do
    context "when returning muid_format" do
      setup do
        @ons_dataset_topic = Factory(:ons_dataset_topic)
      end

      should "return nil if muid is blank" do
        assert_nil Factory.build(:ons_dataset_topic).muid_format
        assert_nil Factory.build(:ons_dataset_topic, :muid => 99).muid_format
        assert_equal "%.1f%", Factory.build(:ons_dataset_topic, :muid => 2).muid_format
      end

    end
  end
end
