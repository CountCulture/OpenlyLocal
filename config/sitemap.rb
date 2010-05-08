# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://openlylocal.com"
SitemapGenerator::Sitemap.yahoo_app_id = YAHOO_API_KEY

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

  # add '/hyperlocal_sites'
  sitemap.add hyperlocal_sites_path, :priority => 0.7, :changefreq => 'daily'

  # add '/police_forces'
  sitemap.add police_forces_path, :priority => 0.7, :changefreq => 'daily'
  
  # add '/police_authorities'
  sitemap.add police_authorities_path, :priority => 0.7, :changefreq => 'daily'
  
  # add '/polls'
  sitemap.add polls_path, :priority => 0.7, :changefreq => 'daily'
  
  # add all councils
  Council.all.each do |c|
    sitemap.add council_path(c), :lastmod => c.updated_at
  end

  # add members
  Member.find_in_batches(:batch_size => 500) do |members|
    members.each do |m|
      sitemap.add member_path(m), :lastmod => m.updated_at
    end
  end

  # add committees
  Committee.find_in_batches(:batch_size => 500) do |committees|
    committees.each do |c|
      sitemap.add committee_path(c), :lastmod => c.updated_at
    end
  end

  # add meetings
  Meeting.find_in_batches(:batch_size => 500) do |meetings|
    meetings.each do |m|
      sitemap.add meeting_path(m), :lastmod => m.updated_at
    end
  end

  # add wards
  Ward.find_in_batches(:batch_size => 500) do |wards|
    wards.each do |w|
      sitemap.add ward_path(w), :lastmod => w.updated_at
    end
  end

  # add police_forces
  PoliceForce.all.each do |force|
    sitemap.add police_force_path(force), :lastmod => force.updated_at
  end

  # add police_authorities
  PoliceAuthority.all.each do |authority|
    sitemap.add police_authority_path(authority), :lastmod => authority.updated_at
  end

  # add police_teams
  PoliceTeam.find_in_batches(:batch_size => 500) do |teams|
    teams.each do |t|
      sitemap.add police_team_path(t), :lastmod => t.updated_at
    end
  end
  
  # add hyperlocal_sites
  HyperlocalSite.approved.all.each do |site|
    sitemap.add hyperlocal_site_path(site), :lastmod => site.updated_at
  end

  # add polls
  Poll.all.each do |poll|
    sitemap.add poll_path(poll), :lastmod => poll.updated_at
  end

  sitemap.add '/info/about_us', :priority => 0.7
  sitemap.add '/info/api', :priority => 0.7
  sitemap.add '/info/licence_info', :priority => 0.7
  
end
