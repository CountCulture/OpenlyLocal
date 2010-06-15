require 'open-uri'
require 'hpricot'
require 'httpclient'

desc "Import Windsor & Maidenhead Supplier Payments"
task :import_windsor_and_maidenhead_supplier_payments => :environment do
  wandm = Council.first(:conditions => "name LIKE '%Windsor%'")
  suppliers = wandm.suppliers
  periods = %w(2009_q1 2009_q2 2009_q3 2009_q4 2010_q1)
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/spending/wandm_supplier_payments_#{period}.csv"), :headers => true) do |row|
      supplier = wandm.suppliers.detect{ |s| row['Supplier ID']&&(s.uid == row['Supplier ID']) || (s.name == row['Supplier Name'])}
      next unless supplier || row['Supplier Name'] || row['Supplier ID'] # skip empty rows
      unless supplier
        supplier ||= wandm.suppliers.create!(:name => row['Supplier Name'], :uid => row['Supplier ID'])
        suppliers << supplier # add to list so we don't create again
        puts "Added new supplier: #{supplier.name}"
      end
      date, date_fuzziness = row['Updated'].blank? ? ["#{period.to_i}-#{period.last.to_i*3-1}-15".to_date, 3*15] : [row['Updated'].gsub('/','-'), nil]# if no date give it date in the middle of the quarter and add appropriate date fuzziness
      supplier.financial_transactions.create!(:uid => row['TransNo'],
                                              :date => date,
                                              :date_fuzziness => date_fuzziness,
                                              :value => row['Amount'],
                                              :transaction_type => row['Type'],
                                              :department_name => row['Directorate'],
                                              :cost_centre => row['Cost Centre'],
                                              :service => row['Service'],
                                              :source_url => 'http://www.rbwm.gov.uk/web/finance_payments_to_suppliers.htm'
                                            )
    end
  end
end

desc "Import GLA Supplier Payments"
task :import_gla_supplier_payments => :environment do
  gla = Council.first(:conditions => {:name => 'Greater London Authority'})
  suppliers = gla.suppliers
  periods = %w(08_2009)
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/gla/#{period}.csv"), :headers => true) do |row|
      supplier = suppliers.detect{ |s| s.name == row['Supplier']}
      next unless supplier || row['Supplier'] # skip empty rows
      unless supplier
        supplier ||= gla.suppliers.create!(:name => row['Supplier'])
        suppliers << supplier # add to list so we don't create again
        puts "Added new supplier: #{supplier.name}"
      end
      date, date_fuzziness = row['Date'].blank? ? ["15-#{period.gsub('_','-')}".to_date, 15] : [row['Date'].gsub('/','-'), nil]# if no date give it date in the middle of the month and add appropriate date fuzziness
      supplier.financial_transactions.create!(:uid => row['Doc No'],
                                              :date => date,
                                              :date_fuzziness => date_fuzziness,
                                              :value => row['Amount'],
                                              :transaction_type => row['Type'],
                                              # :department_name => row['Directorate'],
                                              # :cost_centre => row['Cost Centre'],
                                              :service => row['Expense Description'],
                                              :source_url => 'http://www.london.gov.uk/who-runs-london/greater-london-authority/expenditure-over-1000'
                                            )
    end
  end
end

desc "Match suppliers to companies"
task :match_suppliers_to_companies => :environment do
  unmatched_suppliers = Supplier.all(:conditions => "company_number IS NULL AND (name LIKE '%Ltd%' OR name LIKE '%Limited%' OR name LIKE '%PLC%') AND name !='-1'", :limit => 200)
  unmatched_suppliers.each do |supplier|
    normalised_name = supplier.name.sub(/\bT\/A\b.+/i, '').gsub(/\(.+\)/,'').squish
    client = HTTPClient.new
    resp = client.get("http://companiesopen.org/search?q=#{CGI.escape normalised_name}")
    if resp.status == 303
      company_number = resp.header["Location"].first.scan(/\/(\d+)\//).to_s
      supplier.update_attribute(:company_number, company_number)
      puts "Updated #{supplier.name} with company number #{company_number}"
    elsif (possibles = Hpricot(resp.body.content).search('li a')) && possibles.size > 0
      puts "Found #{possibles.size} possible results for #{supplier.name}: #{possibles.collect(&:inner_text).join(', ')}"
      if likely = possibles.detect{|p| Supplier.normalise_title(p.inner_text) == Supplier.normalise_title(supplier.name)}
        supplier.update_attribute(:company_number, likely[:href].scan(/\/(\d+)\//).to_s)
        puts "Chosen and used company number from #{likely.inner_text}"
      else
        puts '** No suitable match found'
        supplier.update_attribute(:company_number, '-1')
      end
    else
      puts "** No results for #{supplier.name}."
      supplier.update_attribute(:company_number, '-1')
    end
    puts "=======================\n"
    sleep 2 # give server a break
  end
end