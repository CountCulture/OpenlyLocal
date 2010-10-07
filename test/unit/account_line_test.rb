require 'test_helper'

class AccountLineTest < ActiveSupport::TestCase
  context "The AccountLine class" do
    setup do
      @account_line = Factory(:account_line)
    end

    should have_db_column :value
    should have_db_column :period
    should have_db_column :sub_heading

    should belong_to :classification
    should validate_presence_of :classification_id
    should validate_presence_of :organisation_type
    should validate_presence_of :organisation_id
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:account_line, :organisation => organisation).organisation
    end
    
  end

  context "An AccountLine instance" do
    setup do
      @classification = Factory(:classification)
    end
  end
end
