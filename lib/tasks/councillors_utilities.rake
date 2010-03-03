desc "Import councillor twitter ids"
task :import_councillor_twitter_ids => :environment do
  grouped_rows = FasterCSV.read(File.join(RAILS_ROOT, "../shared/csv_data/unmatched_councillor_tweeps.csv"), :headers => true).group_by{ |r| r["Council"] } # group by council
  councils = Council.all
  unmatched_rows = []
  grouped_rows.each do |council_name, rows|
    if council = councils.detect{ |c| Council.normalise_title(council_name) == Council.normalise_title(c.name) }
      puts "=====\nMatched #{council_name} (#{Council.normalise_title(council_name)}) against #{council.title}"
      if council.members.blank?
        puts "No members for this council"
        unmatched_rows += rows
        next
      end
      rows.each do |row|
        if member = council.members.detect { |m| m.last_name == row["CllrSurname"] && m.first_name =~ /#{row["CllrFirstName"]}/ }
          puts "Matched #{row['CllrFirstName']} #{row['CllrSurname']} to #{member.full_name}"
          blog_url = row["CllrWebsite"].blank? ? nil : row["CllrWebsite"]
          member.update_attributes(:twitter_account => row["CllrTwitter"], :blog_url => blog_url)
        else
          puts "**Can't find match for #{row['CllrFirstName']} #{row['CllrSurname']}"
          unmatched_rows << row
        end
      end
    else
      puts "=====\n*****Can't find match for #{council_name} (#{Council.normalise_title(council_name)})"
    end
  end
  
  puts "\n\nWriting #{unmatched_rows.size} unmatched records to file"
  FasterCSV.open(File.join(RAILS_ROOT, "../shared/csv_data/unmatched_councillor_tweeps.csv"), "w") do |csv|
    csv << unmatched_rows.first.headers # write headers
    unmatched_rows.each do |row|
      csv << row
    end
  end
  
end

