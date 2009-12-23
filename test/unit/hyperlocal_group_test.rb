require 'test_helper'

class HyperlocalGroupTest < ActiveSupport::TestCase
  subject { @hyperlocal_site }
  
  context "The HyperlocalGroup class" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_group)
    end
    
    should_validate_uniqueness_of :title
    should_validate_presence_of :title
    should_have_many :hyperlocal_sites      
    
    should_have_db_column :email
    should_have_db_column :url
    
  end
  
  context "A HyperlocalGroup instance" do
    setup do
      @hyperlocal_site = Factory(:hyperlocal_group)
    end
    
  end
end
