desc "Create precis from document bodies"
task :create_document_precis => :environment do
  Document.delete_all('document_owner_id IS NULL AND document_owner_type is NULL')
  Document.find_each(:conditions => {:precis => nil}, :batch_size => 10) do |document|
    if document.document_owner
    document.update_attribute(:precis, document.calculated_precis)
    else
      puts 'No document owner. Deleting document'
    end
  end
end

desc "Import Proclass classification"
task :import_proclass => :environment do
  %w(10.1 8.3).each do |version|
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/ProClass_vC#{version}.csv"), :headers => true) do |row|
      next if row["C#{version}N"].blank?
      levels = [row["Top Level"],row["Level 2"],row["Level 3"]].compact
      Classification.create!(
      :grouping => "Proclass#{version}",
      :uid => row["C#{version}N"],
      :title => levels.last,
      :extended_title => levels.join(' > '))
      print '.'
    end
  end
end

desc "Import CPID entities"
task :import_cpid_entities => :environment do
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/cpid_codes.csv"), :headers => true) do |row|
    next unless entity = Entity.find_by_normalised_title(Entity.normalise_title(row["Name"]))
    entity.update_attribute(:cpid_code, row["Code"])
    print '.'
  end
end

desc "Import Planning Alerts"
task :import_planning_alerts => :environment do
  authority_mapper = {}
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/planning_alerts_authorities.tsv"), :headers => true, :col_sep => "\t") do |row|
    if council = Council.find_by_normalised_title(Council.normalise_title(row["full_name"]))
      council.update_attribute(:signed_up_for_1010, true)
      # puts "Matched planning alerts council #{row['full_name']} with #{council.title}"
      council.update_attribute(:planning_email, row['planning_email']) unless row['planning_email'].blank? || (row['planning_email'] =~ /unknown/)
      authority_mapper[row["authority_id"]] = council.id
    else
      # puts "*** Failed to matched planning alerts council #{row['full_name']}"
    end
  end
  pp authority_mapper
  puts "About to start rejigging planning application table"
  PlanningApplication.find_each do |pl_app|
    if council_id = authority_mapper[pl_app.authority_id.to_s]
      lat,lng = OsCoordsUtilities.convert_os_to_wgs84(pl_app.x, pl_app.y)
      pl_app.update_attributes(:council_id => council_id, :lat => lat, :lng => lng)
      puts '.'
    else
      puts 'x'
    end
  end
  
end

desc "Set up CAPS PlanningApplication scrapers"
task :setup_caps_scrapers => :environment do
  ALL_CAPSIDOX_COUNCILS = 
  [
   "angus",
   "barking & dagenham",
   "basildon",
   "bath & north east somerset",
   "blyth valley",
   "cheltenham",
   "chester-le-street",
   "city of london",
   "congleton",
   "cotswold",
   "devon",
   "durham city",
   "east ayrshire",
   "east devon",
   "east renfrewshire",
   "hart",
   "hull",
   "ipswich",
   "knowsley",
   "lewes",
   "live ",
   "midlothian",
   "newark and sherwood",
   "nottingham",
   "perth & kinross",
   "richmond",
   "ryedale",
   "scarborough",
   "south somerset",
   "southampton",
   "stevenage",
   "stratford-on-avon",
   "sunderland",
   "tameside",
   "test valley",
   "torbay",
   "vale royal",
   "west berkshire",
   "west dunbartonshire",
   "west wiltshire",
   "wigan",
   "wiltshire",
   "winchester",
   ]

  CAPS_COUNCILS = {
    'bexley' => "http://publicaccess.bexley.gov.uk/publicaccess/tdc",
    # 'broads' => 'https://planning.broads-authority.gov.uk/PublicAccess/tdc',
    'bromsgrove' => 'http://appuview.bromsgrove.gov.uk/PublicAccess/tdc',
    'buckinghamshire' => 'http://bucksplanning.buckscc.gov.uk/PublicAccessLive/tdc',
    "caerphilly" => 'http://publicaccess.caerphilly.gov.uk/PublicAccess/tdc',
    'chelmsford' => 'http://web1.chelmsfordbc.gov.uk/publicaccess/tdc',
    "cherwell" => 'http://cherweb.cherwell-dc.gov.uk/publicaccess/tdc',
    "chiltern" => "https://isa.chiltern.gov.uk/publicaccess/tdc",
    'chorley' => 'http://planning.chorley.gov.uk/PublicAccess/TDC/',
    'lambeth' => "http://planning.lambeth.gov.uk/publicaccess/tdc",
    'doncaster' => "http://local.doncaster.gov.uk/PublicAccess/tdc/",
    'dundee' => 'http://bwarrant.dundeecity.gov.uk/publicaccess/tdc/',
    'durham' => "http://planning.chester-le-street.gov.uk/publicaccess/tdc/",
    'east northamptonshire' => 'http://publicaccesssrv.east-northamptonshire.gov.uk/PublicAccess/tdc',
    'fenland' => 'http://www.fenland.gov.uk/publicaccess/tdc/',
    'hammersmith & fulham' => 'http://www.apps.lbhf.gov.uk/PublicAccess/tdc/',
    "harrogate" => 'http://uniformonline.harrogate.gov.uk/online-applications/',
    'hinckley and bosworth' => 'https://cx.hinckley-bosworth.gov.uk/PublicAccess/tdc',
    'huntingdonshire' => 'http://planning.huntsdc.gov.uk/PublicAccess/tdc/',
    'knowsley' => 'http://publicaccess.knowsley.gov.uk/PublicAccess/tdc/',
    'luton' => 'http://www.eplan.luton.gov.uk/PublicAccess/tdc/',
    "northumberland" => 'http://planning.northumberland.gov.uk/PublicAccess/tdc',
    'oadby and wigston' => 'http://pa.owbc.net/PublicAccess/tdc',
    "redditch" => 'http://access.redditchbc.gov.uk/PublicAccess/tdc',
    'richmondshire' => "http://publicaccess.richmondshire.gov.uk/PublicAccess/tdc/",
    'rochford' => 'http://publicaccess.rochford.gov.uk/publicaccess/tdc',
    'sandwell' => "http://webcaps.sandwell.gov.uk/PublicAccess/tdc",
    'selby' => 'http://publicaccess.selby.gov.uk/publicaccess/tdc',
    'sheffield' => 'http://planning.sheffield.gov.uk/publicaccess/tdc/',
    "spelthorne" => 'http://phoenix.spelthorne.gov.uk/PublicAccess/tdc/',
    "staffordshire moorlands" => 'http://publicaccess.staffsmoorlands.gov.uk/publicaccess/tdc/',
    'swindon' => "http://195.89.201.121/PublicAccess77/tdc",
    'southampton' => 'http://publicaccess.southampton.gov.uk/PublicAccess/tdc/',
    "southend on sea" => 'http://planning.southend.gov.uk/PublicAccess/tdc',
    "stirling" => 'http://planpub.stirling.gov.uk/publicaccess/tdc',
    'watford' => 'http://ww3.watford.gov.uk/publicaccess/tdc',
    "waveney" => 'http://publicaccess.waveney.gov.uk/PASystem77/tdc',
    'west lancashire' => 'http://publicaccess.westlancs.gov.uk/PublicAccess/tdc',
    'westminster' => 'http://publicaccess.westminster.gov.uk/PublicAccess/tdc',
    'vale of white horse' => "http://planning.whitehorsedc.gov.uk/publicaccess/tdc/",
    "york" => 'http://planning.york.gov.uk/PublicAccess/tdc/'
  }
  POSS_IDOX_COUNCILS = {
    'newcastle upon tyne' => 'http://planningapplications.newcastle.gov.uk/online-applications',
  }
  IDOX_COUNCILS = {
    'blaby' => 'http://w3.blaby.gov.uk/online-applications',
    'bromley' => 'http://planning.bromley.gov.uk/online-applications/',
    'cheshire west and chester' => 'http://pa.cheshirewestandchester.gov.uk/online-applications',
    "chichester" => 'http://pawam.chichester.gov.uk/online-applications/',
    'comhairle nan eilean siar' => 'http://planning.cne-siar.gov.uk/PublicAccess',
    'cornwall' => 'http://planning.cornwall.gov.uk/online-applications',
    'east hampshire' => 'http://planningpublicaccess.easthants.gov.uk/online-applications',
    "east riding of yorkshire" => 'http://www.eastriding.gov.uk/newpublicaccess/',
    'edinburgh' => 'http://citydev-portal.edinburgh.gov.uk/publicaccess/tdc',
    "epsom & ewell" => 'http://eplanning.epsom-ewell.gov.uk/online-applications',
    'fife' => 'http://planning.fife.gov.uk/online',
    "forest of dean" => 'http://publicaccess.fdean.gov.uk/online-applications',
    "gateshead" => 'http://public.gateshead.gov.uk/online-applications/',
    "gravesham" => 'http://plan.gravesham.gov.uk/online-applications/',
    'hambleton' => 'http://planning.hambleton.gov.uk/online-applications',
    'harborough' => 'http://pa2.harborough.gov.uk/online-applications',
    'huntingdonshire' => 'http://publicaccess.huntsdc.gov.uk/online-applications/',
    'kings lynn and west norfolk' => 'http://online.west-norfolk.gov.uk/online-applications',
    "lancaster" => 'http://planning.lancaster.gov.uk/online-applications/',
    "milton keynes" => 'http://publicaccess2.milton-keynes.gov.uk/online-applications',
    'newcastle under lyme' => 'http://publicaccess.newcastle-staffs.gov.uk/online-applications',
    "north ayrshire" => 'http://www.eplanning.north-ayrshire.gov.uk/OnlinePlanning/',
    'north east derbyshire' => 'http://planapps-online.ne-derbyshire.gov.uk/online-applications/',
    'north tyneside' => 'http://idoxpublicaccess.northtyneside.gov.uk/online-applications/',
    'peterborough' => 'http://planpa.peterborough.gov.uk/online-applications/',
    'sevenoaks' => 'http://pa.sevenoaks.gov.uk/online-applications/',
    'shepway' => 'http://searchplanapps.shepway.gov.uk/online-applications',
    'shetland islands' => 'http://pa.shetland.gov.uk/online-applications',
    'south bucks' => 'http://sbdc-paweb.southbucks.gov.uk/publicaccess/tdc/',
    'south staffordshire' => 'http://www2.sstaffs.gov.uk:81/online-applications',
    'tendring' => 'http://idox.tendringdc.gov.uk/online-applications',
    "thurrock" => 'http://regs.thurrock.gov.uk/online-applications/',
    "tonbridge and malling" => 'http://publicaccess2.tmbc.gov.uk/online-applications/',
    'woking' => 'http://caps.woking.gov.uk/online-applications/',
    'wolverhampton' => 'http://planningonline.wolverhampton.gov.uk:2707/online-applications',
    'argyll and bute' => "http://publicaccess.argyll-bute.gov.uk/publicaccess",
    'bedford' => "http://www.publicaccess.bedford.gov.uk/online-applications",
    'scottish borders' => "http://eplanning.scotborders.gov.uk/online-applications",
    'bradford' => "http://www.planning4bradford.com/online-applications",
    'cambridge' => "http://idox.cambridge.gov.uk/online-applications",
    'corby' => "https://publicaccess.corby.gov.uk/publicaccess",
    'dartford' => "http://publicaccess.dartford.gov.uk/online-applications",
    'east cambridgeshire' => "http://pa.eastcambs.gov.uk/online-applications",
    'east riding of yorkshire' => "http://www.eastriding.gov.uk/newpublicaccess",
    'gedling' => 'http://pawam.gedling.gov.uk:81/online-applications',
    'gloucester' => "http://glcstrplnng12.co.uk/online-applications",
    'gloucestershire' => 'http://planning.gloucestershire.gov.uk/publicaccess/',
    'horsham' => "http://public-access.horsham.gov.uk/public-access",
    'leeds' => 'https://publicaccess.leeds.gov.uk/online-applications',
    'mid sussex' => "http://pa.midsussex.gov.uk/online-applications",
    'newham' => "http://pa.newham.gov.uk/online-applications",
    'norwich' => "http://planning.norwich.gov.uk/online-applications",
    'oxford' => "http://public.oxford.gov.uk/online-applications",
    'portsmouth' => 'http://idox.portsmouth.gov.uk/online-applications/',
    'reading' => "http://planninghome.reading.gov.uk/online-applications",
    'stafford' => "http://www7.staffordbc.gov.uk/online-applications",
    'three rivers' => "http://www3.threerivers.gov.uk/online-applications",
    'torridge' => "http://publicaccess.torridge.gov.uk/online-applications/",
    'tunbridge wells' => "http://pa.tunbridgewells.gov.uk/online-applications",
    'worthing' => "http://planning.adur-worthing.gov.uk/online-applications",
    'wycombe' => "http://publicaccess.wycombe.gov.uk/idoxpa-web"
  }
  
  IDOX_V2_COUNCILS = {
    'manchester' => "http://pa.manchester.gov.uk/online-applications",
    'wakefield' => "https://planning.wakefield.gov.uk/online-applications",
    'salford' => "http://publicaccess.salford.gov.uk/publicaccess"#,
  }
  
  SWIFT_LG = {
    'redbridge' => 'http://planning.redbridge.gov.uk/swiftlg'
  }
  # caps_parser = PortalSystem.find_by_name('CAPS (Public Access)').parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})
  # CAPS_COUNCILS.each do |c,url|
  #   unless council = Council.find_by_normalised_title(Council.normalise_title(c))
  #     puts "******* Failed to match #{c} to council"
  #     next
  #   end
  #   base_url = (url + '/').sub(/\/+$/,'/')
  #   scraper = council.scrapers.find_or_initialize_by_parser_id( :parser_id => caps_parser.id)
  #   scraper.update_attributes!( :parsing_library => 'N', 
  #                               :use_post => true, 
  #                               :frequency => 2,
  #                               :base_url => base_url, 
  #                               :type => 'ItemScraper')
  #   puts "Added CAPS scraper for #{council.name} (#{scraper.inspect})"
  # end
  # 
  # idox_parser = PortalSystem.find_by_name('Idox (Public Access)').parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})
  # IDOX_COUNCILS.each do |c,url|
  #   unless council = Council.find_by_normalised_title(Council.normalise_title(c))
  #     puts "******* Failed to match #{c} to council"
  #     next
  #   end
  #   params = {"date(applicationValidatedStart)"=>["27/09/2011"], 
  #             "action"=>["firstPage"], 
  #             "date(applicationValidatedEnd)"=>["11/10/2011"], 
  #             "searchType"=>["Application"], 
  #             "caseAddressType"=>["Application"] } 
  #   options = {"User-Agent"=>"Mozilla/4.0 (OpenlyLocal.com)"}
  #   client = HTTPClient.new
  #   base_url = url.sub(/\/$/,'')
  #   form_url = base_url +'/advancedSearchResults.do?'
  #   begin
  #     resp = client.post(form_url, params, options)
  #     result = Nokogiri.HTML(resp.content).at('#searchResultsContainer li.searchresult')
  #     puts "#{council.name}: successfully tested Idox URLs"
  #     scraper = council.scrapers.find_or_initialize_by_parser_id( :parser_id => idox_parser.id)
  #     scraper.update_attributes!( :parsing_library => 'N', 
  #                                :use_post => true, 
  #                                :frequency => 2,
  #                                :base_url => base_url, 
  #                                :type => 'ItemScraper')
  #     puts "Added Idox scraper for #{council.name} (#{scraper.inspect})"
  #   rescue Exception => e
  #     puts "#{c}: Problem getting data from #{form_url}"
  #   end
  # 
  # end
end

desc "Add up CAPS InfoScrapers"
task :add_caps_info_scrapers => :environment do
  caps_system = PortalSystem.find_by_name('CAPS (Public Access)')
  item_parser = caps_system.parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})
  info_parser = caps_system.parsers.first(:conditions=>{:scraper_type => 'InfoScraper'})
  item_parser.scrapers.all.each do |scraper|
    info_scraper = InfoScraper.find_or_initialize_by_parser_id_and_council_id(info_parser.id, scraper.council_id)
    info_scraper.update_attributes!( :parsing_library => 'N', 
                                     :use_post => true, 
                                     :frequency => 2,
                                     :priority => 3)
  end
  
end