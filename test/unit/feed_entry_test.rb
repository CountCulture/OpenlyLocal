require 'test_helper'

class FeedEntryTest < ActiveSupport::TestCase
  subject { @feed_entry }
  
  context "The FeedEntry class" do
    setup do
      @feed_entry = Factory(:feed_entry)
    end
    
    should_validate_presence_of :title
    should_validate_presence_of :guid
    should_validate_presence_of :url
    should_have_db_columns :lat, :lng
    
    should "belong to polymorphic feed owner" do
      council = Factory(:council)
      assert_equal council, Factory(:feed_entry, :feed_owner => council).reload.feed_owner
    end
    
    context 'when assigning point' do
      should 'convert to lat long' do
        @feed_entry.point = '45.256 -71.92'
        assert_equal 45.256, @feed_entry.lat
        assert_equal -71.92, @feed_entry.lng
      end
      
      should 'allow comma as separator instead of space' do
        @feed_entry.point = '45.256,-71.92'
        assert_equal 45.256, @feed_entry.lat
        assert_equal -71.92, @feed_entry.lng
      end
      
      should 'not raise exception if nil' do
        assert_nothing_raised(Exception) { @feed_entry.point = nil }
      end
    end

    context "when returning entries for blog" do
      setup do
        owner = Factory(:council)
        owned_entry = Factory(:feed_entry, :feed_owner => owner)
      end
      
      should "return entries with no feed_owner" do
        assert_equal [@feed_entry], FeedEntry.for_blog
      end
    end

    context "when updating feed" do
      setup do
        html_content = "<p>News reaches us that the café at Rowheath<br />Pavilion\r\nwill now be open six<br><br>days a week<a href=\"http://togetherinmission.co.uk/\">Together in Mission</a> who are based at the Pavilion said:</p>\n<p>&lt;a href=&#x27;http://bournvillevillage.com/?p=682&#x27;&gt;hello&lt;/a&gt; world</p>"
        dummy_entry_1 = stub_everything(:title => "Entry 1", :summary => "<p>Entry</p> 1 summary", :url => "foo.com/entry_1", :published => 3.days.ago, :id => "entry_1")
        dummy_entry_2 = stub_everything(:title => "Entry 2", :summary => nil, :content => html_content, :url => "foo.com/entry_2", :point => '45.256 -71.92', :published => 5.days.ago, :id => "entry_2")
        dummy_entry_3 = stub_everything(:title => "Entry 3", :summary => nil, :url => "foo.com/entry_3", :published => 5.days.ago, :id => "entry_3")
        Feedzirra::Feed.stubs(:fetch_and_parse).returns(stub(:entries => [dummy_entry_1, dummy_entry_2, dummy_entry_3]))
      end
      
      should "use Feedzirra to get and parse feed from url" do
        Feedzirra::Feed.expects(:fetch_and_parse).with("foo.com").returns(stub(:entries => []))
        FeedEntry.update_from_feed("foo.com")
      end
      
      should "add entries returned by Feedzirra" do
        assert_difference "FeedEntry.count", 3 do
          FeedEntry.update_from_feed("foo.com")
        end
      end
      
      should "add attributes for feed entry" do
        FeedEntry.update_from_feed("foo.com")
        
        new_entry = FeedEntry.find_by_guid("entry_1")
        assert_equal "Entry 1", new_entry.title
        assert_equal "foo.com/entry_1", new_entry.url
      end
      
      should "strip_tags from summary" do
        FeedEntry.update_from_feed("foo.com")
        assert_equal "Entry 1 summary", FeedEntry.find_by_guid("entry_1").summary
      end
      
      should "not update entries already in db" do
        @existing_entry = Factory(:feed_entry, :title => "Orig title", :guid => "entry_2")
        assert_difference "FeedEntry.count", 2 do
          FeedEntry.update_from_feed("foo.com")
        end
        assert_equal "Orig title", @existing_entry.reload.title
      end
      
      should "save content as summary if no summary" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        
        assert_match /News reaches us/, new_entry.summary
      end
      
      should "strip tags from content for summary" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        
        assert_no_match /<p/, new_entry.summary
      end
      
      should "convert new lines to spaces for summary" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        
        assert_match /Pavilion will/, new_entry.summary
        assert_match /said: hello/, new_entry.summary
      end
      
      should "convert line break tags to spaces for summary" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        
        assert_match /Rowheath Pavilion/, new_entry.summary
        assert_match /six days/, new_entry.summary
      end
      
      should "convert entities to html before stripping tags from content for summary" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        
        assert_match /hello world/, new_entry.summary
      end
      
      should "convert point to lat, lng" do
        FeedEntry.update_from_feed("foo.com")
        new_entry = FeedEntry.find_by_guid("entry_2")
        assert_in_delta 45.256, new_entry.lat, 2 ** -20
        assert_in_delta -71.92, new_entry.lng, 2 ** -20
      end
      
      should "not have errors when no content" do
        assert_nothing_raised(Exception) { FeedEntry.update_from_feed("foo.com") }
      end
      
      context "and asked to update from feed_owner" do
        setup do
          @owner = Factory(:council, :feed_url => "bar.com")
        end
        
        should "use Feedzirra to get and parse feed from owner's feed_url" do
          Feedzirra::Feed.expects(:fetch_and_parse).with("bar.com").returns(stub(:entries => []))
          FeedEntry.update_from_feed(@owner)
        end
        
        should "add entries returned by Feedzirra" do
          assert_difference "FeedEntry.count", 3 do
            FeedEntry.update_from_feed(@owner)
          end
        end
        
        should "associate entries with feed_owner" do
          FeedEntry.update_from_feed(@owner)
          assert_equal @owner, FeedEntry.find_by_guid("entry_1").feed_owner
        end
        
      end
      
    end
    
    context "when performing" do
      setup do
        dummy_entry_1 = stub_everything(:title => "Entry 1", :summary => "Entry 1 summary", :url => "foo.com/entry_1", :published => 3.days.ago, :id => "entry_1")
        dummy_entry_2 = stub_everything(:title => "Entry 2", :summary => "Entry 2 summary", :url => "foo.com/entry_2", :published => 5.days.ago, :id => "entry_2")
        Feedzirra::Feed.stubs(:fetch_and_parse).returns(stub(:entries => [dummy_entry_1, dummy_entry_2]))
        @council = Factory(:council, :feed_url => "bar.com")
        Council.stubs(:all).returns([@council])
      end
      
      should "get Council with feed_urls" do
        Council.expects(:all).with(has_entry(:conditions => "feed_url IS NOT NULL AND feed_url !=''")).returns([])
        FeedEntry.perform
      end
      
      should "get hyperlocal_sites with feed_urls" do
        HyperlocalSite.expects(:all).with(has_entry(:conditions => "feed_url IS NOT NULL AND feed_url !=''")).returns([])
        FeedEntry.perform
      end
      
      should "update feeds for councils" do
        Council.stubs(:all).returns([@council])
        FeedEntry.expects(:update_from_feed).with(@council)
        FeedEntry.perform
      end
      
      should "update feeds for hyperlocal_sites" do
        FeedEntry.stubs(:update_from_feed)
        hyperlocal_site = Factory(:hyperlocal_site)
        HyperlocalSite.stubs(:all).returns([hyperlocal_site])
        
        FeedEntry.expects(:update_from_feed).with(hyperlocal_site)
        FeedEntry.perform
      end
      
      should "update feeds for blog" do
        FeedEntry.stubs(:update_from_feed)
        FeedEntry.expects(:update_from_feed).with(BlogFeedUrl)
        FeedEntry.perform
      end
      
      should "not raise exception if problem getting data" do
        FeedEntry.expects(:update_from_feed).raises
        assert_nothing_raised(Exception) { FeedEntry.perform }
      end
      
      should "email report of processing" do
        AdminMailer.expects(:deliver_admin_alert!)
        FeedEntry.perform
      end
      
      should "list number of items updated in email" do
        FeedEntry.perform
        assert_sent_email do |email|
          email.subject =~ /Feed Updating Report/i && email.body =~ /updated feeds for 2 items/m
        end
      end
      
      should "list problems incurred when updating" do
        FeedEntry.stubs(:update_from_feed).returns(nil).then.raises
        FeedEntry.perform
        assert_sent_email do |email|
          email.subject =~ /1 problems/m &&
          email.subject =~ /1 successes/m &&
          email.body =~ /1 problems/m &&
          email.body =~ /Error> raised.+ #{BlogFeedUrl}/m
        end
      end
    end
  end
  
end
