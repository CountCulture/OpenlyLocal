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

  caps_portal_system = PortalSystem.find_by_name('CAPS (Public Access)')
  
  caps_item_parser = Parser.create(
    :scraper_type => 'ItemScraper',
    :result_model => "PlanningApplication",
    :portal_system => caps_portal_system,
    :path => %q{ DcApplication/application_searchresults.aspx?searchtype=ADV&srchDateValidStart=#{30.days.ago.to_date.strftime("%d/%m/%Y")}&srchDateValidEnd=#{Date.today.strftime("%d/%m/%Y")} },
    :cookie_path => nil,
    :item_parser => %q{ doc.search('table.cResultsForm tr')[1..-1] },
    :attribute_parser => {
      'url' => %q{ base_url + item.search('td a').last[:href].sub('publicaccess/tdc/','') },
      'uid' => %q{ item.at('td').inner_text }
    }
  )

  caps_parser = caps_portal_system.parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})

  # Destroy existing scrapers for the CAPS item parser
  caps_parser.scrapers.destroy_all

  # Create CAPS scrapers from list
  CAPS_COUNCILS.each do |c,url|
    unless council = Council.find_by_normalised_title(Council.normalise_title(c))
      puts "******* Failed to match #{c} to council"
      next
    end
    base_url = (url + '/').sub(/\/+$/,'/')
    scraper = council.scrapers.find_or_initialize_by_parser_id( :parser_id => caps_parser.id)
    scraper.update_attributes!( :parsing_library => '8', 
                                :use_post => true, 
                                :frequency => 2,
                                :base_url => base_url, 
                                :type => 'ItemScraper')
    puts "Added CAPS scraper for #{council.name} (#{scraper.inspect})"
  end
  
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
    scraper.update_attribute(:base_url, scraper.base_url.sub(/\/$/,''))
    info_scraper.update_attributes!( :parsing_library => 'N', 
                                     :use_post => true, 
                                     :frequency => 1,
                                     :priority => 3)
  end
end

desc "Add FastWEB portal system"
task :add_fastweb_portal_system => :environment do
  begin
    unless PortalSystem.find_by_name("FastWEB")
      fastweb_portal = PortalSystem.create(:name => "FastWEB", :url => "http://www.innogistic.co.uk/eplanning.php")
    end
  rescue Exception => e
    puts "Couldn't create FastWEB portal system: #{e}"
  end 
end

desc "Create FastWEB item parser"
task :add_fastweb_item_parser => :environment do
  portal_system = PortalSystem.find_by_name("FastWEB")
  begin
    parser = Parser.create(
      :portal_system => portal_system,
      :scraper_type => 'ItemScraper',
      :description => "FastWEB item parser",
      :result_model => 'PlanningApplication',
      :path =>          'results.asp?Scroll=1&DateReceivedStart=#{14.days.ago.strftime("%d-%m-%Y")}&DateReceivedEnd=#{0.days.ago.strftime("%d-%m-%Y")}&Sort1=DateReceived+DESC&Sort2=DateReceived+DESC&Submit=Search',
      :item_parser => %{item.search("//table[@border='0' and @cellspacing='0' and @cellpadding='4' and @width='100%']")},
      :attribute_parser => {
        'uid' => %{item.css("a").first.inner_text},
        'url' => %{base_url + item.css("a").first[:href].sub(/detail/, 'fulldetail')} # Don't add a / after the base_url as that always ends with a / itself
      }
    )
  rescue Exception => e
    puts "Error creating FastWEB parser: #{e}"
  end  
end

FASTWEB_COUNCILS = {
  'craven' =>             'http://www.planning.cravendc.gov.uk/fastweb/',
  'eastleigh' =>          'http://www.eastleigh.gov.uk/fastweb',
  'wyre forest' =>        'http://www.wyreforest.gov.uk/fastweb',
  'mansfield' =>          'http://www.mansfield.gov.uk/fastweb',
  'neath port talbot' =>  'https://planning.npt.gov.uk',
  'newport' =>            'http://www.newport.gov.uk/fastWeb',
  'sutton' =>             'http://213.122.180.105/FASTWEB/',
  'south lakeland' =>     'http://www.southlakeland.gov.uk/fastweb',
  'eden' =>               'http://eforms.eden.gov.uk/fastweb'
}

desc "Create FastWEB item scrapers for all councils"
task :add_fastweb_item_scrapers => :environment do

  parser = PortalSystem.find_by_name('FastWEB').parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})

  FASTWEB_COUNCILS.each do |c,url|
    unless council = Council.find_by_normalised_title(Council.normalise_title(c))
      puts "******* Failed to match #{c} to council"
      next
    end
    base_url = (url + '/').sub(/\/+$/,'/') # Ensure that there's exactly one forward slash at the end of the base_url
    scraper = council.scrapers.find_or_initialize_by_parser_id(:parser_id => parser.id)
    scraper.update_attributes!( :parsing_library => 'N', 
                                :use_post => false, 
                                :frequency => 2,
                                :base_url => base_url, 
                                :type => 'ItemScraper')
    # STI 'type' column can't be mass-assigned, apparently: http://stackoverflow.com/a/1503967
    scraper[:type] = 'ItemScraper'
    scraper.save                                
    puts "Added scraper for #{council.name} (#{scraper.inspect})"
  end
end

desc "Create FastWEB info parser"
task :add_fastweb_info_parser => :environment do
  portal_system = PortalSystem.find_by_name("FastWEB")
  begin
    parser = Parser.create(
      :portal_system => portal_system,
      :scraper_type => 'InfoScraper',
      :description => "FastWEB info parser",
      :result_model => 'PlanningApplication',
      :path =>          '',
      :item_parser => %{item.at("body")},
      :attribute_parser => {
        'uid' =>      %q{item.at("//th[@class='RecordTitle' and .='Planning Application Number:']/../td").inner_text.strip},
        'address' =>      %q{item.at("//th[@class='RecordTitle' and .='Site Address:']/../td").inner_text.strip.gsub(/\s{2,}/, ', ')},
        'description' =>      %q{item.at("//th[@class='RecordTitle' and .='Description:']/../td").inner_text.strip},
        'status' =>      %q{item.at("//th[@class='RecordTitle' and .='Application Status:']/../td").inner_text.strip},
        'date_valid' =>      %q{item.at("//th[@class='RecordTitle' and .='Date Valid:']/../td").inner_text.strip},
        'decision' =>      %q{item.at("//th[@class='RecordTitle' and .='Decision:']/../td").inner_text.strip},
        'decision_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Decision Date:']/../td").inner_text.strip},
        'decision_level_or_committee' =>      %q{item.at("//th[@class='RecordTitle' and .='Decision Level/Committee:']/../td").inner_text.strip},
        'appeal' =>      %q{item.at("//th[@class='RecordTitle' and .='Appeal:']/../td").inner_text.strip},
        'case_officer_and_phone_number' =>      %q{item.at("//th[@class='RecordTitle' and .='Case Officer and Phone No.:']/../td").inner_text.strip},
        'applicant_name' =>      %q{item.at("//th[@class='RecordTitle' and .='Applicant Name & Address:']/../td").inner_html.sub(/<br\s*\/?>.*/i, '').strip},
        'applicant_address' =>      %q{item.at("//th[@class='RecordTitle' and .='Applicant Name & Address:']/../td").inner_html.sub(/.*<br\s*\/?>/i, '').strip.gsub(/\s{2,}/, ', ').strip},
        'agent_name' =>      %q{item.at("//th[@class='RecordTitle' and .='Agent Name & Address:']/../td").inner_html.sub(/<br\s*\/?>.*/i, '').strip},
        'agent_address' =>      %q{item.at("//th[@class='RecordTitle' and .='Agent Name & Address:']/../td").inner_html.sub(/.*<br\s*\/?>/i, '').strip.gsub(/\s{2,}/, ', ').strip},
        'ward' =>      %q{item.at("//th[@class='RecordTitle' and .='Ward:']/../td").inner_text.strip},
        'parish' =>      %q{item.at("//th[@class='RecordTitle' and .='Parish:']/../td").inner_text.strip},
        'listed_building_grade' =>      %q{item.at("//th[@class='RecordTitle' and .='Listed Building Grade:']/../td").inner_text.strip},
        'departure_from_local_plan' =>      %q{item.at("//th[@class='RecordTitle' and .='Departure from Local Plan:']/../td").inner_text.strip},
        'major_development' =>      %q{item.at("//th[@class='RecordTitle' and .='Major Development:']/../td").inner_text.strip},
        'date_received' =>      %q{item.at("//th[@class='RecordTitle' and .='Date Received:']/../td").inner_text.strip},
        'committee_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Committee Date:']/../td").inner_text.strip},
        'deferred' =>      %q{item.at("//th[@class='RecordTitle' and .='Deferred:']/../td").inner_text.strip},
        'deferred_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Deferred Date:']/../td").inner_text.strip},
        'temporary_expiry_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Temporary Expiry Date:']/../td").inner_text.strip},
        'site_notice_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Site Notice Date:']/../td").inner_text.strip},
        'advert_date' =>      %q{item.at("//th[@class='RecordTitle' and .='Advert Date:']/../td").inner_text.strip},
        'consulation_period_begins' =>      %q{item.at("//th[@class='RecordTitle' and .='Consultation Period Begins:']/../td").inner_text.strip},
        'consulation_period_ends' =>      %q{item.at("//th[@class='RecordTitle' and .='Consultation Period Ends:']/../td").inner_text.strip}
      }
    )
  rescue Exception => e
    puts "Error creating FastWEB parser: #{e}"
  end  
end


desc "Create FastWEB info scrapers for all councils"
task :add_fastweb_info_scrapers => :environment do

  parser = PortalSystem.find_by_name('FastWEB').parsers.first(:conditions=>{:scraper_type => 'InfoScraper'})

  FASTWEB_COUNCILS.each do |c,url|
    unless council = Council.find_by_normalised_title(Council.normalise_title(c))
      puts "******* Failed to match #{c} to council"
      next
    end
#     base_url = (url + '/').sub(/\/+$/,'/') # Ensure that there's exactly one forward slash at the end of the base_url
    scraper = council.scrapers.find_or_initialize_by_parser_id(:parser_id => parser.id)
    scraper.update_attributes!( :parsing_library => 'N', 
                                :use_post => false, 
                                :frequency => 1,
                                :priority => 3,
                                :base_url => '', 
                                :type => 'InfoScraper')
    # STI 'type' column can't be mass-assigned, apparently: http://stackoverflow.com/a/1503967
    scraper[:type] = 'InfoScraper'
    scraper.save
    puts "Added scraper for #{council.name} (#{scraper.inspect})"
  end
end

# From http://onrails.org/2008/08/20/what-are-all-the-rails-date-formats
desc "Show the date/time format strings defined and example output"
task :date_formats => :environment do
  now = Time.now
  [:to_date, :to_datetime, :to_time].each do |conv_meth|
    obj = now.send(conv_meth)
    puts obj.class.name
    puts "=" * obj.class.name.length
    name_and_fmts = obj.class::DATE_FORMATS.map { |k, v| [k, %Q('#{String === v ? v : '&proc'}')] }
    max_name_size = name_and_fmts.map { |k, _| k.to_s.length }.max + 2
    max_fmt_size = name_and_fmts.map { |_, v| v.length }.max + 1
    name_and_fmts.each do |format_name, format_str|
      puts sprintf("%#{max_name_size}s:%-#{max_fmt_size}s %s", format_name, format_str, obj.to_s(format_name))
    end
    puts
  end
end

desc "Import last four years planning applications for Idox scrapers"
task :import_last_four_years_planning_applications => :environment do
  puts "Please enter name of Portal System:"
  portal_system_name = $stdin.gets.chomp
  idox_parser = PortalSystem.find_by_name(portal_system_name).parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})
  scrapers = idox_parser.scrapers.all(:limit => 1)
  scrapers.each do |scraper|
    puts "About to get past planning applications for #{scraper.council.name}"
    204.times do |i|
      start_date, end_date = (7*i + 21).days.ago.strftime("%d/%m/%Y"), (7*i + 14).days.ago.strftime("%d/%m/%Y") 
      cookie_url = scraper.cookie_url.sub(/\#\{[^{]+\}/, start_date) # replace start date
      cookie_url = cookie_url.sub(/\#\{[^{]+\}/, end_date) # replace end date
      puts "About to process scraper from #{start_date} to #{end_date} (from #{cookie_url})"
      scraper.process(:cookie_url => cookie_url, :save_results => true)
    end
  end
end

# task :import_last_four_years_pas_for_lichfield => :environment do
#   c = Council.find(156)
#   1000.times.do |i|
#     date_query = i.days.ago.strftime("day=%d&month=%m&year=%Y")
#     puts "Getting applications for #{i.days.ago} from http://www2.lichfielddc.gov.uk/planning/alerts.php?#{date_query}"
#     doc = Nokogiri.XML(open "http://www2.lichfielddc.gov.uk/planning/alerts.php?#{date_query}")
#     doc.search('applications>application').each do |application|
#       print '.'
#       pa = PlanningApplication.find_or_initialize_by_council_id_and_uid(c.id, application.at('council_reference').inner_text.strip)
#       pa.update_attributes( :url => application.at('info_url').inner_text.strip,
#                             :comment_url => application.at('comment_url').inner_text.strip,
#                             :address => application.at('address').inner_text.strip,
#                             :postcode => application.at('postcode').inner_text.strip,
#                             :description => application.at('description>').inner_text.strip,
#                             :date_received => application.at('date_recieved>').inner_text.strip,
#                             :postcode => application.at('postcode').inner_text.strip
#                           )
#     end
#   end
# end
# 
task :remove_duplicate_planning_applications => :environment do
  Council.all.each do |council|
    next if council.planning_applications.count == 0
    dup_uids = PlanningApplication.count(:select => :uid, :conditions => {:council_id => council.id}, :group => :uid, :having => 'count_uid > 1').keys
    destroy_count = 0
    dup_uids.each do |uid|
      destroy_count += PlanningApplication.find_all_by_council_id_and_uid(council.id, uid)[1..-1].each(&:destroy).size
    end
    puts "Destroyed #{destroy_count} duplicate planning_applications for #{council.name}"
  end
end

# @todo PostGIS update this code
task :convert_old_confirmed_planning_alert_subscribers => :environment do
  sql= "SELECT COUNT(*) FROM planning_alert_subscribers WHERE confirmed = 1 LIMIT 10"
  connection = AlertSubscriber.connection
  total_count = connection.select_rows(sql).flatten.first.to_i
  dump_file = Rails.root.join('db','data','old_confirmed_alert_subscribers.csv')
  headers = connection.columns('planning_alert_subscribers').collect(&:name)
  FasterCSV.open(dump_file, "w") do |csv|
    csv << headers
    (total_count/1000 + 1).each do |page|
      sql = "SELECT planning_alert_subscribers.* FROM planning_alert_subscribers WHERE confirmed = 1 LIMIT 1000 OFFSET #{page*1000}"
      rows = connection.select_rows(sql)
      rows.each do |row|
        csv << row_converted_to_lat_lng(row, headers)
      end
    end
  end
end

task :convert_caps_urls_to_idox_urls => :environment do
  puts "Please enter name of Council:"
  break unless council = Council.find_by_normalised_title(Council.normalise_title($stdin.gets.chomp))
  base_url = council.scrapers.first(:conditions => 'scrapers.type = "ItemScraper" AND parsers.result_model = "PlanningApplication"', 
                                    :joins => :parser).base_url
  
  puts "About to rework old CAPS urls to new Idox ones for #{council.title} and base_url #{base_url}"
  ok_to_update = 'N'
  council.planning_applications.find_each do |pa|
    # p "OLD url = #{pa.url}"
    next unless pa.url.match(/PublicAccess\/tdc/i)
    old_url = pa.url
    uid = pa.url.scan(/\w+$/).first
    new_url = base_url + "/applicationDetails.do?activeTab=summary&keyVal=" + uid
    case ok_to_update
    when 'A'
      # do nothing
    else 
      puts "About to update planning application with new url #{new_url} (was #{old_url}). Continue [Y/N/A]"
      ok_to_update = $stdin.gets.chomp
      next if $stdin.gets.chomp == 'N'
    end
    pa.update_attribute(:url, new_url)
    puts "Updated planning application with new url #{new_url} (was #{old_url})"
  end
end

def row_converted_to_lat_lng(row, headers)
  row_hash = [headers,row].transpose.inject({}){ |hsh,a| hsh[a.first] = a.last; hsh }
  sw_lat_lng = OsCoordsUtilities.convert_os_to_wgs84(row_hash.delete('bottom_left_x'), row_hash.delete('bottom_left_y'))
  ne_lat_lng = OsCoordsUtilities.convert_os_to_wgs84(row_hash.delete('top_right_x'), row_hash.delete('top_right_y'))
  row_hash['bottom_left_lat'], row_hash['bottom_left_lng'] = sw_lat_lng
  row_hash['top_right_lat'], row_hash['top_right_lng']     = ne_lat_lng
  row_hash
end