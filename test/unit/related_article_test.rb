require 'test_helper'
# require 'pingback_engine'

class RelatedArticleTest < ActiveSupport::TestCase
  subject { @related_article }
  
  context "The RelatedArticle class" do
    setup do
      @related_article = Factory(:related_article)
    end
    
    should_validate_presence_of :url
    should_validate_presence_of :title
    should_validate_presence_of :hyperlocal_site_id
    should_validate_presence_of :subject_type, :subject_id
    should_validate_uniqueness_of :url
    should_belong_to :hyperlocal_site
    should_have_db_columns :extract
    
    should 'belong to subject polymorphically' do
      subject = Factory(:member, :council => Factory(:another_council))
      assert_equal subject, Factory(:related_article, :subject => subject).subject
    end
    
    context 'when processing pingback' do
      setup do
        @subject = Factory(:member, :council => Factory(:another_council))
        @hyperlocal_site = Factory(:hyperlocal_site, :url => 'http://foo.com/home/page.php')
        @pingback_attribs = {:title => 'A new article', :source_uri => 'http://foo.com/referring/article.html', :content => "some words", :target_uri => "http://openlylocal.com/members/#{@subject.id}-Fred-Flinstone"}
        @pingback = stub(@pingback_attribs)
        HyperlocalSite.stubs(:find_from_article_url).returns(@hyperlocal_site)
      end
      
      context 'and pingback is valid' do
        setup do
          @resp = RelatedArticle.process_pingback(@pingback)
          @new_related_article = RelatedArticle.find_by_title('A new article')
        end
        
        should_create :related_article
        
        should 'assign info from ping to new related_article' do
          assert_equal 'http://foo.com/referring/article.html', @new_related_article.url
          assert_equal 'A new article', @new_related_article.title
          assert_equal 'some words', @new_related_article.extract
        end
        
        before_should 'find approved hyperlocal_site that published article' do
          HyperlocalSite.expects(:find_from_article_url).with('http://foo.com/referring/article.html').returns(@hyperlocal_site)
        end
        
        should 'associate hyperlocal_site with related_article' do
          assert_equal @hyperlocal_site, @new_related_article.hyperlocal_site
        end
        
        should 'associate related_article with article subject' do
          assert_equal @subject, @new_related_article.subject
        end
        
        should 'return appropriate success response' do
          assert_equal true, @resp
        end
      end
      
      context 'and pingback is for non-OpenlyLocal url' do
        setup do
          @resp = RelatedArticle.process_pingback(stub(@pingback_attribs.merge(:target_uri => "http://openlyclosed.com/members/#{@subject.id}-Fred-Flinstone")))
        end
        
        should_not_change("Related Article count") { RelatedArticle.count }
        
        should 'return appropriate failure response' do
          assert_equal false, @resp
        end
      end
      
      context "and pingback is for OpenlyLocal url that doesn't accept pingbacks" do
        setup do
          twitter_account = Factory(:twitter_account)
          @resp = RelatedArticle.process_pingback(stub(@pingback_attribs.merge(:target_uri => "http://openlylocal.com/twitter_accounts/#{twitter_account.id}-fred")))
        end
        
        should_not_change("Related Article count") { RelatedArticle.count }
        
        should 'return appropriate failure response' do
          assert_equal false, @resp
        end
      end
      
      context "and pingback is for OpenlyLocal url that can't accept pingbacks" do
        setup do
          twitter_account = Factory(:twitter_account)
          @resp = RelatedArticle.process_pingback(stub(@pingback_attribs.merge(:target_uri => "http://openlylocal.com/info/about_us")))
        end
        
        should_not_change("Related Article count") { RelatedArticle.count }
        
        should 'return appropriate failure response' do
          assert_equal false, @resp
        end
      end
      
      context "and pingback is for url that isn't from approved hyperlocal_site" do
        setup do
          twitter_account = Factory(:twitter_account)
          HyperlocalSite.expects(:find_from_article_url) # => nil
          @resp = RelatedArticle.process_pingback(stub(@pingback_attribs))
        end
        
        should_not_change("Related Article count") { RelatedArticle.count }
        
        should 'return appropriate failure response' do
          assert_equal false, @resp
        end
      end
    end
  end
end
