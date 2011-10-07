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
  CAPS_COUNCILS = {
  'argyll' => "http://www.argyll-bute.gov.uk/PublicAccess/tdc/",
  'bedford' => "http://www.publicaccess.bedford.gov.uk/publicaccess/dc/",
  'bexley' => "http://publicaccess.bexley.gov.uk/publicaccess/tdc/",
  'bradford' => "http://www.planning4bradford.com/publicaccess/tdc/",
  'cambridge' => "http://www.cambridge.gov.uk/publicaccess/tdc/",
  'chester-le-street' => "http://planning.chester-le-street.gov.uk/publicaccess/tdc/",
  'corby' => "http://publicaccess.corby.gov.uk/publicaccess/tdc/",
  'dartford' => "http://publicaccess.dartford.gov.uk/publicaccess/tdc/",
  'doncaster' => "http://maps.doncaster.gov.uk/publicaccess/tdc/",
  'eastcambs' => "http://pa.eastcambs.gov.uk/publicaccess/tdc/",
  'eastriding' => "http://www.eastriding.gov.uk/PublicAccess731c/dc/",
  'gloucester' => "http://www.glcstrplnng11.co.uk/publicaccess/tdc/",
  'horsham' => "http://publicaccess.horsham.gov.uk/publicaccess/tdc/",
  'lambeth' => "http://planning.lambeth.gov.uk/publicaccess/dc/",
  'leeds' => "http://planningapplications.leeds.gov.uk/publicaccess/tdc/",
  'manchester' => "http://www.publicaccess.manchester.gov.uk/publicaccess/tdc/",
  'midsussex' => "http://dc.midsussex.gov.uk/PublicAccess/tdc/",
  'staffordshire' => "http://62.173.124.237/publicaccess/tdc/",
  'newham' => "http://pacaps.newham.gov.uk/publicaccess/tdc/",
  'ne-derbyshire' => "http://planapps-online.ne-derbyshire.gov.uk/publicaccess/dc/",
  'norwich' => "http://publicaccess.norwich.gov.uk/publicaccess/tdc/",
  'oxford' => "http://uniformpublicaccess.oxford.gov.uk/publicaccess/tdc/",
  'reading' => "http://planning.reading.gov.uk/publicaccess/tdc/",
  'richmondshire' => "http://publicaccess.richmondshire.gov.uk/PublicAccess/tdc/",
  'rochford' => "http://62.173.68.168/publicaccess/dc/",
  'salford' => "http://publicaccess.salford.gov.uk/publicaccess/dc/",
  'sandwell' => "http://webcaps.sandwell.gov.uk/publicaccess/tdc/",
  'borders' => "http://eplanning.scotborders.gov.uk/publicaccess/tdc/",
  'stafford' => "http://www3.staffordbc.gov.uk/publicaccess/tdc/",
  'swindon' => "http://194.73.99.13/publicaccess/tdc/",
  'threerivers' => "http://www2.threerivers.gov.uk/publicaccess/tdc/",
  'torridge' => "http://www.torridge.gov.uk/publicaccess/tdc/",
  'tunbridgewells' => "http://secure.tunbridgewells.gov.uk/publicaccess/tdc/",
  'whitehorse' => "http://planning.whitehorsedc.gov.uk/publicaccess/tdc/",
  'wakefield' => "http://planning.wakefield.gov.uk/publicaccess/tdc/",
  'westwiltshire' => "http://planning.westwiltshire.gov.uk/PublicAccess/tdc/",
  'worthing' => "http://planning.worthing.gov.uk/publicaccess/tdc/",
  'wycombe' => "http://planningpa.wycombe.gov.uk/publicaccess/tdc/"
}
  
  
end