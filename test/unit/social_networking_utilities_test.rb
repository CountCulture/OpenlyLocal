require 'test_helper'

class SocialNetworkingUtilitiesTest < ActiveSupport::TestCase
  
  context 'A class that mixes in SocialNetworkingUtilities::Base' do
    should 'mixin TwitterAccountMethods' do
      assert TestModelWithSocialNetworking.new.respond_to?(:twitter_account)
    end
    
    should 'have update_social_networking_details method' do
      assert TestModelWithSocialNetworking.new.respond_to?(:update_social_networking_details)
    end
    
    context 'and when updating social networking details' do
      setup do
        @test_model = TestModelWithSocialNetworking.create!
        @test_model_with_existing_details = TestModelWithSocialNetworking.create!(:twitter_account_name => 'foo', :blog_url => 'http://foo.com/blog', :facebook_account_name => 'baz123')
        @new_details = SocialNetworkingDetails.new(:twitter_account_name => 'bar', :blog_url => 'http://bar.com/blog', :facebook_account_name => 'baz456')
      end
      
      should 'set twitter account if not set' do
        @test_model.update_social_networking_details(@new_details)
        assert_equal 'bar', @test_model.reload.twitter_account_name
      end
      
      should 'update twitter account if set' do
        @test_model_with_existing_details.update_social_networking_details(@new_details)
        assert_equal 'bar', @test_model_with_existing_details.reload.twitter_account_name
      end
      
      should 'not delete existing twitter account if nil given for twitter_account_name' do
        @test_model_with_existing_details.update_social_networking_details(SocialNetworkingDetails.new(:twitter_account_name => nil))
        assert_equal 'foo', @test_model_with_existing_details.reload.twitter_account_name
      end
      
      should 'set blog url if not set' do
        @test_model.update_social_networking_details(@new_details)
        assert_equal 'http://bar.com/blog', @test_model.reload.blog_url
      end
      
      should 'update blog url if set' do
        @test_model_with_existing_details.update_social_networking_details(@new_details)
        assert_equal 'http://bar.com/blog', @test_model_with_existing_details.reload.blog_url
      end
      
      should 'not delete existing blog_url if nil given for blog_url' do
        @test_model_with_existing_details.update_social_networking_details(SocialNetworkingDetails.new(:blog_url => nil))
        assert_equal 'http://foo.com/blog', @test_model_with_existing_details.reload.blog_url
      end
      
      should 'set facebook account if not set' do
        @test_model.update_social_networking_details(@new_details)
        assert_equal 'baz456', @test_model.reload.facebook_account_name
      end
            
      should 'update facebook account if set' do
        @test_model_with_existing_details.update_social_networking_details(@new_details)
        assert_equal 'baz456', @test_model_with_existing_details.reload.facebook_account_name
      end
      
      should 'not delete existing facebook_account_name if nil given for facebook_account_name' do
        @test_model_with_existing_details.update_social_networking_details(SocialNetworkingDetails.new(:facebook_account_name => nil))
        assert_equal 'baz123', @test_model_with_existing_details.reload.facebook_account_name
      end
      
      should 'return true by default' do
        @test_model.update_social_networking_details(@new_details)
        @test_model_with_existing_details.update_social_networking_details(@new_details)
      end
      
      should 'return false if problem updating_attributes' do
        @test_model.stubs(:update_attributes).returns(false)
        assert_equal false, @test_model.update_social_networking_details(@new_details)
      end
      
      context "when hash is submitted" do
        setup do
          @new_details_hash = { :twitter_account_name => 'bar', :blog_url => 'http://bar.com/blog', :facebook_account_name => 'baz456' }
        end

        should "update from hash" do
          @test_model.update_social_networking_details(@new_details_hash)
          assert_equal 'http://bar.com/blog', @test_model.reload.blog_url
          assert_equal 'baz456', @test_model.facebook_account_name
          assert_equal 'bar', @test_model.twitter_account_name
        end
        
        should "not raise error when social networking type returned that isn't attribute of model" do
          assert_nothing_raised(Exception) { @test_model.update_social_networking_details(@new_details_hash.merge(:youtube_account_name => 'fred45')) }
          assert_equal 'http://bar.com/blog', @test_model.reload.blog_url
        end
      end
    end
    
    context "when updating social networking details from website" do
      setup do
        @test_model = TestModelWithSocialNetworking.create!(:url => 'http://foo.com')
      end

      should "find social networking details on url" do
        SocialNetworkingUtilities::Finder.expects(:new).with('http://foo.com').returns(stub(:process => {}))
        @test_model.update_social_networking_details_from_website
      end
      
      should "update social networking details from info found on website" do
        SocialNetworkingUtilities::Finder.any_instance.expects(:process).returns(:facebook_account_name => 'foobar')
        @test_model.expects(:update_social_networking_details).with(:facebook_account_name => 'foobar')
        @test_model.update_social_networking_details_from_website
      end
      
      should "not find social networking details if no url" do
        @test_model.url = nil
        SocialNetworkingUtilities::Finder.any_instance.expects(:process).never
        @test_model.update_social_networking_details_from_website
      end
            
    end
  end

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
      
      should "return youtube account name" do
        assert_equal "StratfordDC", @finder.process[:youtube_account_name]
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
  
  context "the IdExtractor class" do
    context "when extracting from URL" do
      should "return empty hash by default" do
        assert_equal( {}, SocialNetworkingUtilities::IdExtractor.extract_from())
        assert_equal( {}, SocialNetworkingUtilities::IdExtractor.extract_from(""))
        assert_equal( {}, SocialNetworkingUtilities::IdExtractor.extract_from(nil))
      end
      
      should "return nil if cant extract id from URL" do
        assert_equal( {}, SocialNetworkingUtilities::IdExtractor.extract_from("http://foo.com"))
      end
      
      should "return hash of attribute and value from and it can extract it from URL" do
        expect_result = {:twitter_account_name => "foo123"}
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://twitter.com/foo123")
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("twitter.com/foo123")
      end
      
      should "return twitter name from twitter URLs" do
        expect_result = {:twitter_account_name => "foo123"}
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://twitter.com/foo123")
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("twitter.com/foo123")
      end
      
      should "extract facebook name from Facebook URL" do
        expect_result = {:facebook_account_name => "foo123"}
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://www.facebook.com/foo123")
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://facebook.com/foo123")
      end
      
      should "extract youtube name from Facebook URL" do
        expect_result = {:youtube_account_name => "foo123"}
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://www.youtube.com/foo123")
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://www.youtube.com/user/foo123")
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from("http://youtube.com/foo123")
      end
      
      should "return hash of multiple ids from multiple urls" do
        expect_result = {:twitter_account_name => "foo123", :facebook_account_name => "bar456"}
        assert_equal expect_result, SocialNetworkingUtilities::IdExtractor.extract_from(["http://twitter.com/foo123", "facebook.com/bar456"] )
      end
    end
  end
  
end