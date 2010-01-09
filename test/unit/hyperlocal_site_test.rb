require 'test_helper'

class HyperlocalSiteTest < ActiveSupport::TestCase
  subject { @hyperlocal_site }
  
  context "The HyperlocalSite class" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_site)
    end
    
    should_validate_uniqueness_of :title
    should_validate_presence_of :title
    should_validate_presence_of :url
    should_validate_uniqueness_of :url
    should_belong_to :hyperlocal_group
    should_belong_to :council
    should_allow_values_for :platform, "Ning"
    should_not_allow_values_for :platform, "foo"
    
    should_have_db_column :email
    should_have_db_column :description
    should_have_db_column :lat
    should_have_db_column :lng
    should_have_db_column :distance
    should_have_db_column :twitter_account
    should_have_db_column :feed_url
    should_have_db_column :platform
    should_have_db_column :area_covered
    should_have_db_column :country
    
    should "validate presence of lat on create" do
      h = Factory.build(:hyperlocal_site, :lat => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:lat]
      @hyperlocal_site.update_attribute(:lat, nil)
      assert @hyperlocal_site.valid?
    end
     
    should "validate presence of lng on create" do
      h = Factory.build(:hyperlocal_site, :lng => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:lng]
      @hyperlocal_site.update_attribute(:lng, nil)
      assert @hyperlocal_site.valid?
    end   
    
    should "validate presence of distance on create" do
      h = Factory.build(:hyperlocal_site, :distance => nil)
      assert !h.valid?
      assert_equal "can't be blank", h.errors[:distance]
      @hyperlocal_site.update_attribute(:distance, nil)
      assert @hyperlocal_site.valid?
    end   
  end
  
  context "A HyperlocalSite instance" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_site)
    end
    
  end
  
end
