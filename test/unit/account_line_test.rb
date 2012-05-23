require File.expand_path('../../test_helper', __FILE__)

class AccountLineTest < ActiveSupport::TestCase
  context "The AccountLine class" do
    setup do
      @account_line = Factory(:account_line)
    end

    [:value, :period, :sub_heading].each do |column|
      should have_db_column column
    end

    should belong_to :classification
    [:classification_id, :organisation_type, :organisation_id, :period].each do |attribute|
      should validate_presence_of attribute
    end
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:account_line, :organisation => organisation).organisation
    end
    
  end

  context "An AccountLine instance" do
    setup do
      @account_line = Factory(:account_line)
    end
  end
end
