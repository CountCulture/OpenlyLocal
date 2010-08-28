require 'test_helper'

class CharityTest < ActiveSupport::TestCase

  context "The Charity class" do
    setup do
      @charity = Factory(:charity)
    end
    should have_many :supplying_relationships

    should have_db_column :title
    should have_db_column :activities
    should have_db_column :charity_number
    should have_db_column :website
    should have_db_column :email
    should have_db_column :telephone
    should have_db_column :date_registered
    should have_db_column :charity_commission_url
    should validate_presence_of :charity_number
    should validate_presence_of :title
    should validate_uniqueness_of :charity_number
    should have_db_column :vat_number
    should have_db_column :contact_name
    should have_db_column :accounts_date
    should have_db_column :spending
    should have_db_column :income
    
    should "mixin SpendingStat::Base module" do
      assert Charity.new.respond_to?(:spending_stat)
    end

    
  end
end
