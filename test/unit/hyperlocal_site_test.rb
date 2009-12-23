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
    
    should_have_db_column :email
    should_have_db_column :lat
    should_have_db_column :lng
    should_have_db_column :distance
    should_have_db_column :twitter_account
    should_have_db_column :feed_url
        
  end
  
  context "A HyperlocalSite instance" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_site)
    end
    
  end
  
end
