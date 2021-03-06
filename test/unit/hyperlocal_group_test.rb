require File.expand_path('../../test_helper', __FILE__)

class HyperlocalGroupTest < ActiveSupport::TestCase
  subject { @hyperlocal_group }
  
  context "The HyperlocalGroup class" do
    setup do
      @hyperlocal_group = Factory(:hyperlocal_group)
    end
    
    should validate_uniqueness_of :title
    should validate_presence_of :title
    
    should have_db_column :email
    should have_db_column :url
    
    should "have many hyperlocal sites" do
      approved_site = Factory(:approved_hyperlocal_site, :hyperlocal_group => @hyperlocal_group)
      approved_site_for_another_group = Factory(:approved_hyperlocal_site, :hyperlocal_group => Factory(:hyperlocal_group))
      unapproved_site = Factory(:hyperlocal_site, :hyperlocal_group => @hyperlocal_group)
      assert_equal [approved_site], @hyperlocal_group.hyperlocal_sites
    end

  end
  
  context "A HyperlocalGroup instance" do
    setup do
      @hyperlocal_group = Factory(:hyperlocal_group)
    end
    
    should "use title when converting to_param" do
      @hyperlocal_group.title = "some title-with/stuff"
      assert_equal "#{@hyperlocal_group.id}-some-title-with-stuff", @hyperlocal_group.to_param
    end

  end
end
