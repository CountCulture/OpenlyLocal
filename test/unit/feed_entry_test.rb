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

    context "when updating feed" do
      setup do
        dummy_entry_1 = stub(:title => "Entry 1", :summary => "Entry 1 summary", :url => "foo.com/entry_1", :published => 3.days.ago, :id => "entry_1")
        dummy_entry_2 = stub(:title => "Entry 2", :summary => "Entry 2 summary", :url => "foo.com/entry_2", :published => 5.days.ago, :id => "entry_2")
        Feedzirra::Feed.stubs(:fetch_and_parse).returns(stub(:entries => [dummy_entry_1, dummy_entry_2]))
      end
      
      should "use Feedzirra to get and parse feed from url" do
        Feedzirra::Feed.expects(:fetch_and_parse).with("foo.com").returns(stub(:entries => []))
        FeedEntry.update_from_feed("foo.com")
      end
      
      should "add entries returned by Feedzirra" do
        assert_difference "FeedEntry.count", 2 do
          FeedEntry.update_from_feed("foo.com")
        end
      end
      
      should "add attributes for feed entry" do
        FeedEntry.update_from_feed("foo.com")
        
        new_entry = FeedEntry.find_by_guid("entry_1")
        assert_equal "Entry 1", new_entry.title
        assert_equal "Entry 1 summary", new_entry.summary
        assert_equal "foo.com/entry_1", new_entry.url
      end
      
      should "not update entries already in db" do
        @existing_entry = Factory(:feed_entry, :title => "Orig title", :guid => "entry_2")
        assert_difference "FeedEntry.count", 1 do
          FeedEntry.update_from_feed("foo.com")
        end
        assert_equal "Orig title", @existing_entry.reload.title
      end
      
    end
    
  end
  
  # context "An FeedEntry instance" do
  #   
  #   context "when setting and getting full_name" do
  #     setup do
  #       NameParser.stubs(:parse).returns(:first_name => "Fred", :last_name => "Scuttle", :name_title => "Prof", :qualifications => "PhD")
  #       @feed_entry = FeedEntry.new(:full_name => "Fred Scuttle")
  #     end
  #   
  #     should "return full name" do
  #       assert_equal "Fred Scuttle", @feed_entry.full_name
  #     end
  #   end
  # end
end
