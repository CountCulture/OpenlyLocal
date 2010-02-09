class FeedEntry < ActiveRecord::Base
  belongs_to :feed_owner, :polymorphic => true
  validates_presence_of :guid, :url, :title
  named_scope :for_blog, :conditions => "feed_owner_type IS NULL AND feed_owner_id IS NULL"
  default_scope :order => "published_at DESC"
  
  def self.update_from_feed(owner_or_url)
    url = owner_or_url.is_a?(String) ? owner_or_url : owner_or_url.feed_url
    feed_owner = owner_or_url.is_a?(String) ? nil : owner_or_url
    feed = Feedzirra::Feed.fetch_and_parse(url)
    add_entries(feed.entries, :feed_owner => feed_owner)
  end
  
  def self.perform
    items = Council.all(:conditions => "feed_url IS NOT NULL AND feed_url !=''")
    items += HyperlocalSite.all(:conditions => "feed_url IS NOT NULL AND feed_url !=''")
    items << BlogFeedUrl
    errors = []
    items.each do |item|
      begin
        update_from_feed(item)
        logger.debug { "Successfully update feed entries for #{item.inspect}" }
      rescue Exception => e
        logger.debug { "Problem getting feed entries for #{item.inspect}: #{e.inspect}" }
        errors << [e, item]
        items.delete(item)
      end
    end
    errors_text = "\n========\n#{errors.size} problems" + 
                    errors.collect{ |err, item| "\n#{err.inspect} raised while getting feed entries from " + 
                    (item.is_a?(String) ? item : "#{item.feed_url} (#{item.title})") }.join
    AdminMailer.deliver_admin_alert!( :title => "RSS Feed Updating Report: #{items.size} successes, #{errors.size} problems", 
                                      :details => "Successfullly updated feeds for #{items.size} items\n" + errors_text)
  end
    
  
  private
  def self.add_entries(entries, options={})
    entries.each do |entry|
      unless exists? :guid => entry.id
        create!(
          :title        => entry.title,
          :summary      => entry.summary,
          :url          => entry.url,
          :published_at => entry.published,
          :guid         => entry.id,
          :feed_owner   => options[:feed_owner]
        )
      end
    end
  end
  
end
