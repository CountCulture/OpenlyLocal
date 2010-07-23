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
  
  periods = Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'gla'))[2..-1].collect{ |p| p.sub('.csv','') }
  puts "About to add data for #{periods.size} periods"
  periods.each do |period|
    puts "=============\nAdding transactions for #{period}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/gla/#{period}.csv"), :headers => true) do |row|
      supplier = suppliers.detect{ |s| s.name == (row['Supplier']||row['Vendor'])}
      next unless supplier || row['Supplier']||row['Vendor'] # skip empty rows
      if supplier
        puts "Matched existing supplier: #{supplier.title}"
      else
        supplier ||= gla.suppliers.create!(:name => row['Supplier']||row['Vendor'])
        suppliers << supplier # add to list so we don't create again
        puts "Added new supplier: #{supplier.name}"
      end
      date, date_fuzziness = row['Date'].blank? ? ["15-#{period.gsub('_','-')}".to_date, 15] : [row['Date'].gsub('/','-'), nil]# if no date give it date in the middle of the month and add appropriate date fuzziness
      supplier.financial_transactions.create!(:uid => row['Doc No'],
                                              :date => date,
                                              :date_fuzziness => date_fuzziness,
                                              :value => row['Amount'],
                                              :transaction_type => row['Doc Type'],
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
  unmatched_suppliers = Supplier.all(:conditions => "company_number IS NULL AND (name LIKE '%Ltd%' OR name LIKE '%Limited%' OR name LIKE '%PLC%')", :limit => 200)
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

desc "Move supplier info to company model"
task :move_supplier_info_to_company => :environment do
  Supplier.all(:conditions => "company_number IS NOT NULL AND company_number != '-1'").each do |supplier|
    company = Company.find_or_create_by_company_number(:company_number => supplier.company_number, :title => supplier.name, :url => supplier.url)
    supplier.update_attribute(:company, company)
  end
end

desc "Import LB Richmond Supplier Payments"
task :import_richmond_supplier_payments => :environment do
  richmond = Council.first(:conditions => "name LIKE '%Richmond%'")
  suppliers = richmond.suppliers
  periods = %w(06_2010)
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_richmond/supplier_payments_#{period}.csv"), :headers => true) do |csv_file|
      csv_file.each do |row|
            supplier = suppliers.detect{ |s| s.name == row['Supplier']}
            next unless supplier || row['Supplier'] # skip empty rows
            unless supplier
              supplier ||= richmond.suppliers.create!(:name => row['Supplier'])
              suppliers << supplier # add to list so we don't create again
              puts "Added new supplier: #{supplier.name}"
            end
            date, date_fuzziness = row['Date'].blank? ? ["15-#{period.gsub('_','-')}".to_date, 15] : [row['Date'].gsub('/','-'), nil]# if no date give it date in the middle of the month and add appropriate date fuzziness
            supplier.financial_transactions.create!(:uid => row['Doc No'],
                                                    :date => date,
                                                    :date_fuzziness => date_fuzziness,
                                                    :value => row['Value'],
                                                    :csv_line_number => csv_file.lineno,
                                                    # :transaction_type => row['Type'],
                                                    :department_name => row['Directorate'],
                                                    # :cost_centre => row['Cost Centre'],
                                                    :service => row['Type of Expenditure'],
                                                    :source_url => 'http://www.richmond.gov.uk/june_expenses.csv'
                                                  )
    end

    end
  end
end

desc "Import NDPBs"
task :import_ndpbs => :environment do
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/ndpbs.csv"), :headers => true) do |row|
    Quango.find_or_create_by_title(:title => row['Name'], :quango_type => 'NDPB', :quango_subtype => row['QuangoSubType'], :sponsoring_organisation => row['SponsoringBody'])
  end
end

desc "Import Surrey CC Supplier Payments"
task :import_surrey_supplier_payments => :environment do
  surrey = Council.first(:conditions => "name LIKE '%Surrey%'")
  date = "30-04-2010".to_date
  puts "Adding transactions for Sutton"
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/surrey_cc/surrey_cc_spending_april_may_2010.csv"), :headers => true) do |row|
    ft = FinancialTransaction.new(:date => date,
                                       :date_fuzziness => 30,
                                       :value => row['Total Value (Net)'],
                                       :supplier_name => row['Vendor Name'],
                                       :supplier_uid => row['Vendor Number'],
                                       :organisation => surrey,
                                       :service => row['Material Group'],
                                       :source_url => 'http://www.surreycc.gov.uk/sccwebsite/sccwspages.nsf/LookupWebPagesByTITLE_RTF/Opening+the+books+on+the+cost+of+goods+and+services?opendocument'
                                       )
    ft.save!                                  
    puts "."
  end
end

desc "Import Uttlesford Supplier Payments"
task :import_uttlesford_supplier_payments => :environment do
  uttlesford = Council.first(:conditions => "name LIKE '%Uttlesford%'")
  puts "Adding transactions for Uttlesford"
  supplier, transactions = nil, []
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/uttlesford/june_2010.csv"), :headers => true) do |row|
    if supplier_name = row["Supplier Name"]
      transactions.each do |ft_row|
        ft = FinancialTransaction.new(     :date => row["Date"].gsub('/','-'),
                                           :value => ft_row['Value'],
                                           :cost_centre => ft_row["Cost Centre"],
                                           :supplier_name => supplier_name,
                                           :uid => ft_row['Doc Ref'],
                                           :organisation => uttlesford,
                                           :service => ft_row["Cost Centre Description"],
                                           :source_url => 'http://www.uttlesford.gov.uk/uttlesford/file/Supplier%20Payments%20Greater%20than%20500%20June%202010.xls'
                                           )
        ft.save!                                  
        puts "."
        transactions = [] # reset
      end
    else
      transactions << row
    end
  end
end

desc "Import King's Lynn & West Norfolk Payments"
task :import_kl_and_wn_payments => :environment do
  klandwn = Council.first(:conditions => "name LIKE '%West Norfolk%'")
  # periods = ['April 2010', 'May 2010']
  periods = ['June 2010']
  puts "Adding transactions for King's Lynn & West Norfolk"
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/kl_and_w_norfolk/Payments to Suppliers #{period}.csv"), :headers => true) do |csv_file|
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row['PAYMENT DATE'].sub('-10','-2010').gsub('/', '-'),
                                      :value => row['PAYMENT'],
                                      :supplier_name => row['SUPPLIER NAME'],
                                      :organisation => klandwn,
                                      :csv_line_number => csv_file.lineno,
                                      :service => row['SERVICE/ACTIVITY'],
                                      :description => row['DETAIL'],
                                      :transaction_type => row['TYPE'],
                                      :source_url => "http://www.west-norfolk.gov.uk/files/Payments%20to%20Suppliers%20#{period.gsub(' ','%20')}.csv"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  klandwn.spending_stat.perform
end
    
