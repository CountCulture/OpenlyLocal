require 'test_helper'

class OnsDatasetTest < ActiveSupport::TestCase
  subject { @ons_dataset }
  
  context "The OnsDataset class" do
    setup do
      @ons_dataset = Factory(:ons_dataset) 
    end
    should_validate_presence_of :start_date 
    should_validate_presence_of :end_date
    should_validate_presence_of :dataset_family_id
    should_validate_uniqueness_of :start_date, :scoped_to => :dataset_family_id

    should_belong_to :dataset_family
    
    should  "return date range as title" do
      assert_equal "#{@ons_dataset.start_date} - #{@ons_dataset.end_date}", @ons_dataset.title
    end
    
    should  "return title of dataset_family and date range as extended_title" do
      assert_equal "#{@ons_dataset.dataset_family.title} #{@ons_dataset.start_date} - #{@ons_dataset.end_date}", @ons_dataset.extended_title
    end
  end 
end
