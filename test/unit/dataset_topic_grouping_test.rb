require File.expand_path('../../test_helper', __FILE__)

class DatasetTopicGroupingTest < ActiveSupport::TestCase
  subject { @dataset_topic_grouping }
  context "The DatasetTopicGrouping class" do
    setup do
      @dataset_topic_grouping = Factory(:dataset_topic_grouping)
    end

    should validate_presence_of :title
    should have_many :dataset_topics
    should have_many :datasets
    [:display_as, :sort_by].each do |column|
      should have_db_column column
    end
  end
end
