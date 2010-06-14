require 'test_helper'

class OldDatapointTest < ActiveSupport::TestCase

  context "The OldDatapoint class" do

    should_have_db_columns :data
    should_validate_presence_of :data, :old_dataset_id, :council_id
    
    should belong_to :council
    should belong_to :old_dataset
  end
  
  context "An OldDatapoint instance" do
    setup do
      @datapoint = Factory.create(:old_datapoint, :data => [["heading_1", "heading_2"],["data_1", "data_2"]])
    end

    should "serialize data" do
      assert_equal [["heading_1", "heading_2"],["data_1", "data_2"]], @datapoint.reload.data
    end
    
    context "with dataset with summary column" do
      setup do
        @datapoint.old_dataset.update_attribute(:summary_column, 1)
      end

      should "delegate summary_column to associated dataset" do
        assert_equal 1, @datapoint.summary_column
      end

      should "return summary for associated dataset" do
        assert_equal ["heading_2", "data_2"], @datapoint.summary
      end
    end
    
    context "with dataset with no summary column" do
      should "return nil for summary" do
        assert_nil @datapoint.summary
      end
    end
    
  end
  
end
