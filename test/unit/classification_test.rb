require 'test_helper'

class ClassificationTest < ActiveSupport::TestCase
  context "The OutputAreaClassification class" do
    setup do
      @classification = Factory(:classification)
    end

    should validate_presence_of :title
    should validate_presence_of :grouping
    should have_db_column :grouping
    should have_db_column :extended_title
    should have_db_column :parent_id
    
    # should_validate_uniqueness_of :uid, :scoped_to => :area_type
  end

  context "A OutputAreaClassification instance" do
    setup do
      @classification = Factory(:classification)
    end
    
  end
end
