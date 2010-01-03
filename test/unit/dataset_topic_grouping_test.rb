require 'test_helper'

class DatasetTopicGroupingTest < ActiveSupport::TestCase
  subject { @dataset_topic_grouping }
  context "The DatasetTopicGrouping class" do
    setup do
      @dataset_topic_grouping = Factory(:dataset_topic_grouping)
    end

    should_validate_presence_of :title
    should_have_many :dataset_topics
    should_have_db_columns :display_as, :sort_by
  end
end
