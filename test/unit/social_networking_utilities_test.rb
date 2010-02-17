require 'test_helper'

class SocialNetworkingUtilitiesTest < ActiveSupport::TestCase
  
  context "An instance of the Finder class" do
    setup do
      @finder = SocialNetworkingUtilities::Finder.new("http://foo.com")
    end
    
    should "store given url as accessor" do
      assert_equal "http://foo.com", @finder.url
    end
    
    context "when processing" do
      setup do
        @council_home_page = dummy_html_response(:council_home_page)
        SocialNetworkingUtilities::Finder.any_instance.stubs(:_http_get).returns(@council_home_page)
      end
      
      should "get page" do
        @finder.expects(:_http_get).with("http://foo.com").returns(@council_home_page)
        @finder.process
      end
      
      should "process page with Hpricot" do
        dummy_hpricot_resp = Hpricot("foo")
        Hpricot.expects(:parse).with(@council_home_page).returns(dummy_hpricot_resp)
        @finder.process
      end
      
      should "return hash" do
        assert_kind_of Hash, @finder.process
      end
      
      should "return twitter account name" do
        assert_equal "stratforddc", @finder.process[:twitter_account_name]
      end
      
      should "return facebook account name" do
        assert_equal "StratfordDC", @finder.process[:facebook_account_name]
      end
      
      should "return news_feed url" do
        assert_equal "http://www.stratford.gov.uk/files/news/news.xml", SocialNetworkingUtilities::Finder.new("http://www.stratford.gov.uk").process[:feed_url]
      end
      
      should "not fail when social networking links missing" do
        @finder.expects(:_http_get).returns("<html><body>Not much here</body></html>")
        assert_nothing_raised() { @finder.process }
      end
    end
  end
  
end