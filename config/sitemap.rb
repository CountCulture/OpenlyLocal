# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://openlylocal.com"

SitemapGenerator::Sitemap.add_links do |sitemap|
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: sitemap.add path, options
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly', 
  #           :lastmod => Time.now, :host => default_host

  
  # Examples:
  
  # add '/councils'
  sitemap.add councils_path, :priority => 0.7, :changefreq => 'daily'

  # add parsed councils
  Council.parsed.each do |c|
    sitemap.add council_path(c), :lastmod => c.updated_at
  end

  # add members
  Member.all.each do |m|
    sitemap.add member_path(m), :lastmod => m.updated_at
  end

  # add committees
  Committee.all.each do |c|
    sitemap.add committee_path(c), :lastmod => c.updated_at
  end

  # add meetings
  Meeting.all.each do |m|
    sitemap.add meeting_path(m), :lastmod => m.updated_at
  end

  sitemap.add '/info/about_us', :priority => 0.7
  
end
