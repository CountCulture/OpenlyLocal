require 'test_helper'

class StatisticalDatasetTest < ActiveSupport::TestCase
  
  subject { @statistical_dataset }
  context "The StatisticalDataset class" do
    setup do
      @statistical_dataset = Factory(:statistical_dataset)
    end

    should_have_db_columns :title, :description, :url, :originator, :originator_url
    should_validate_presence_of :title, :originator
    should_validate_uniqueness_of :title
    should_have_many :ons_dataset_families

  end

end
