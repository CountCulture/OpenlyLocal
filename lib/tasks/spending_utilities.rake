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

desc "OLD Import GLA Supplier Payments"
task :old_import_gla_supplier_payments => :environment do
  gla = Council.first(:conditions => {:name => 'Greater London Authority'})
  suppliers = gla.suppliers
  
  # periods = Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'gla'))[2..-1].collect{ |p| p.sub('.csv','') }
  periods = %w(06_2010)
  puts "About to add data for #{periods.size} periods"
  periods.each do |period|
    puts "=============\nAdding transactions for #{period}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/gla/#{period}.csv"), :headers => true) do |row|
      supplier = suppliers.detect{ |s| s.name == (row['Supplier']||row['Vendor'])}
      next unless supplier || row['Supplier']||row['Vendor'] # skip empty rows
      if supplier
        # puts "Matched existing supplier: #{supplier.title}"
      else
        supplier ||= gla.suppliers.create!(:name => row['Supplier']||row['Vendor'])
        suppliers << supplier # add to list so we don't create again
        puts "Added new supplier: #{supplier.name}"
      end
      date, date_fuzziness = row['Date'].blank? ? ["14-#{period.gsub('_','-')}".to_date, 15] : [row['Date'].gsub('/','-'), nil]# if no date give it date in the middle of the month and add appropriate date fuzziness
      supplier.financial_transactions.create!(:uid => row['Doc No'],
                                              :date => date,
                                              # :date_fuzziness => date_fuzziness,
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

# Service Area,Expenditure Type,Vendor Name,Entry Date,Ref.Doc., Expenditure
desc "Import Barnet Payments"
task :import_barnet_payments => :environment do
  barnet = Council.first(:conditions => "name LIKE '%Barnet%'")
  puts "Adding transactions for Barnet"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_barnet/expenditure_by_supplier_apr_to_jun_10.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      ft = FinancialTransaction.new(:date => row['Entry Date'],
                                    :value => row['Expenditure'],
                                    :supplier_name => row['Vendor Name'],
                                    :organisation => barnet,
                                    :csv_line_number => csv_file.lineno + 2, #we've deleted first two lines which we comments
                                    :department_name => row['Service Area'],
                                    :service => row['Expenditure Type'],
                                    :uid => row['Ref.Doc.'],
                                    :source_url => "http://www.barnet.gov.uk/expenditure_by_supplier_apr_to_jun_10.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  barnet.spending_stat.perform
end
    
desc "Export CSV version of spending data"
task :export_csv_spending_data  => :environment do
  require 'zip/zipfilesystem'
  dir = File.join(RAILS_ROOT, "db/data/downloads/")
  csv_file = File.join(dir, "spending.csv")
  Dir.mkdir(dir) unless File.directory?(dir)
  FasterCSV.open(csv_file, "w") do |csv|
    csv << (headings = FinancialTransaction::CsvMappings.collect{ |m| m.first })
    FinancialTransaction.find_each do |financial_transaction|
      csv << financial_transaction.csv_data
    end
  end

  Zip::ZipFile.open("#{csv_file}.zip", Zip::ZipFile::CREATE) {
    |zipfile|
    zipfile.add('spending.csv', csv_file)
  }
  File.delete(csv_file)
end  

desc "Import Islington Payments"
task :import_islington_payments => :environment do
  islington = Council.first(:conditions => "name LIKE '%Islington%'")
  periods = ['04_2010', '05_2010']
  puts "Adding transactions for Islington"
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_islington/#{period}.csv"), :headers => true) do |csv_file|
      date = "14_#{period}".gsub('_','-').to_date
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => date,
                                      :date_fuzziness => 13,
                                      :value => row['Gross Amount'],
                                      :supplier_name => row['Supplier Name'],
                                      :organisation => islington,
                                      :service => row['Description'],
                                      :source_url => "http://www.islington.gov.uk/DownloadableDocuments/CouncilandDemocracy/Pdf/#{Date::MONTHNAMES[date.month].downcase}_published_version.pdf"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  islington.spending_stat.perform
end

desc "Import Bedford Payments"
task :import_bedford_payments => :environment do
  bedford = Council.first(:conditions => "name LIKE '%Bedford Borough%'")
  periods = ['04_2010', '05_2010', '06_2010', '07_2010']
  puts "Adding transactions for Barnet"
  periods.each do |period|
    puts "Adding transactions for #{period}"
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/bedford/Invoices_#{period}.csv"), :headers => true) do |csv_file|
      date = "14_#{period}".gsub('_','-').to_date
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => date,
                                      :date_fuzziness => 13,
                                      :value => row['Amount'],
                                      :supplier_name => row['Supplier'],
                                      :department_name => row['Directorate'],
                                      :organisation => bedford,
                                      :uid => row['TransNo'],
                                      :source_url => "http://www.bedford.gov.uk/council_and_democracy/council_budgets_and_spending/supplier_payments.aspx"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  bedford.spending_stat.perform
end

desc "Import Bromley Payments"
task :import_bromley_payments => :environment do
  bromley = Council.first(:conditions => "name LIKE '%Bromley%'")
  puts "Adding transactions for Bromley"
  date = "14-06-2010"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_bromley/PaymentstosuppliersJun10Invoices.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      ft = FinancialTransaction.new(:date => date,
                                    :date_fuzziness => 13,
                                    :value => row['Invoice amount'],
                                    :supplier_name => row['Supplier name'],
                                    :organisation => bromley,
                                    :csv_line_number => csv_file.lineno + 2, #we've deleted first two lines which were comments
                                    :department_name => row['Portfolio'],
                                    :service => row['Service area'],
                                    :uid => row['Payment reference number'],
                                    :invoice_number => row['Invoice reference number'],
                                    :description => row['Expense type'],
                                    :source_url => "http://www.bromley.gov.uk/NR/rdonlyres/7D69F0B1-E5DB-4757-9ACD-ED4719529249/0/PaymentstosuppliersJun10Invoices.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  bromley.spending_stat.perform
end

desc "Import Kensington & Chelsea Payments"
task :import_kandc_payments => :environment do
  kandc = Council.first(:conditions => "name LIKE '%Chelsea%'")
  puts "Adding transactions for Kensington & Chelsea"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_kandc/PaymentsSchedule010410-300610.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      ft = FinancialTransaction.new(:date => row['Supplier invoice date'].gsub('/', '-'),
                                    :value => row['Total Invoice amount excl VAT'],
                                    :supplier_name => row['Supplier mailing name'],
                                    :organisation => kandc,
                                    :csv_line_number => csv_file.lineno, #we've deleted first two lines which were comments
                                    :department_name => row['Business Groups'],
                                    :service => row['Service Area'],
                                    :supplier_uid => row['RBKC Supplier No'],
                                    :invoice_number => row['Supplier Invoice Reference number'],
                                    :supplier_vat_number => row['VAT No'],
                                    :source_url => "http://www.rbkc.gov.uk/files/PaymentsSchedule010410-300610.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  kandc.spending_stat.perform
end

desc "Import Spotlight on Spend data"
task :import_spotlight_on_spend_data => :environment do
  council_files = Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'spotlight_on_spend')).select{ |f| f.match('csv') }
  
  council_files.each do |council_file|
    council = Council.find_by_normalised_title(Council.normalise_title(council_file.sub(/ line level.+/,'')))
    next unless council.suppliers.count == 0
    puts "Adding transactions for #{council.title}"
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/spotlight_on_spend/#{council_file}"), :headers => true) do |csv_file|
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row['Invoice/Item Date'].gsub('/', '-'),
                                      :value => row['Item Amount (Net)'],
                                      :supplier_name => row['Payee'],
                                      :organisation => council,
                                      :csv_line_number => csv_file.lineno, 
                                      :department_name => row['Department'],
                                      :invoice_number => row['Invoice ID'],
                                      :source_url => "http://spotlightonspend-rawdata.s3.amazonaws.com/#{council_file.sub('.csv','.zip').gsub(' ', '%20')}"
                                      )
        ft.save!                                  
        puts "."
      end
    end
    council.spending_stat.perform
  end
end

desc "Import Devon County Council Payments"
task :import_devon_cc_payments => :environment do
  devon = Council.first(:conditions => "name LIKE '%Devon %'")
  puts "Adding transactions for Devon County Council"
  periods = %w(may10 june10 july10)
  periods.each do |period|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/devon_cc/finance-payments-over500-#{period}.csv"), :headers => true) do |csv_file|
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row['Payment Date'].gsub('/', '-'),
                                      :value => row['Total Excl VAT'],
                                      :supplier_name => row['Creditor Name'],
                                      :supplier_uid => row['Creditor No'],
                                      :organisation => devon,
                                      :csv_line_number => csv_file.lineno,
                                      :uid => row['Payment Number'],
                                      :source_url => "http://www.devon.gov.uk/finance-payments-over500-#{period}.xls"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  devon.spending_stat.perform
end

desc "Import Lewes Payments"
task :import_lewes_payments => :environment do
  lewes = Council.first(:conditions => "name LIKE '%Lewes%'")
  puts "Adding transactions for Lewes"
  date = "14-06-2010"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lewes/1011_Payments.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      ft = FinancialTransaction.new(:date => row['Date'].gsub('/', '-'),
                                    :value => row['Amount'],
                                    :supplier_name => row['Supplier'],
                                    :organisation => lewes,
                                    :csv_line_number => csv_file.lineno,
                                    :department_name => row['Section'],
                                    :uid => row['Ref'],
                                    :source_url => "http://www.lewes.gov.uk/Files/1011_Payments.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  lewes.spending_stat.perform
end

desc "Import Wigan Payments"
task :import_wigan_payments => :environment do
  wigan = Council.first(:conditions => "name LIKE '%Wigan%'")
  puts "Adding transactions for Wigan"
  date = "14-06-2010"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/wigan/SupplierPuchases-April-June2010.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      ft = FinancialTransaction.new(:date => row['Transaction Date'].gsub('/', '-'),
                                    :value => row['Amount'],
                                    :supplier_name => row['Suplpier Name'],
                                    :organisation => wigan,
                                    :csv_line_number => csv_file.lineno,
                                    :department_name => row['Department'],
                                    :service => row['Service Area'],
                                    :invoice_number => row['Invoice Number'],
                                    :source_url => "http://www.wigan.gov.uk/pub/SupplierPuchases-April-June2010.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  wigan.spending_stat.perform
end

# desc "Import Walsall Payments"
# task :import_walsall_payments => :environment do
#   walsall = Council.first(:conditions => "name LIKE '%Walsall%'")
#   puts "Adding transactions for Wigan"
#   date = "14-06-2010"
#   FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/walsall/SupplierPuchases-April-June2010.csv"), :headers => true) do |csv_file|
#     csv_file.each do |row|
#       ft = FinancialTransaction.new(:date => row['Transaction Date'].gsub('/', '-'),
#                                     :value => row['Amount'],
#                                     :supplier_name => row['Suplpier Name'],
#                                     :organisation => walsall,
#                                     :csv_line_number => csv_file.lineno,
#                                     :department_name => row['Department'],
#                                     :service => row['Service Area'],
#                                     :invoice_number => row['Invoice Number'],
#                                     :source_url => "http://www.wigan.gov.uk/pub/SupplierPuchases-April-June2010.csv"
#                                     )
#       ft.save!                                  
#       puts "."
#     end
#   end
#   walsall.spending_stat.perform
# end
desc "Import Wandsworth Supplier Payments"
task :import_wandsworth_supplier_payments => :environment do
  wandsworth = Council.first(:conditions => "name LIKE '%Wandsworth%'")
  date = "14-07-2010".to_date
  puts "Adding transactions for Wandsworth"
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/spending/lb_wandsworth/july20100811.csv"), :headers => true) do |row|
    ft = FinancialTransaction.new(:date => date,
                                       :date_fuzziness => 13,
                                       :value => row['Sum of Amount'],
                                       :supplier_name => row['Payee'],
                                       :organisation => wandsworth,
                                       :source_url => 'http://www.wandsworth.gov.uk/download/3362/july_2010_expenditure_items'
                                       )
    ft.save!                                  
    puts "."
  end
  wandsworth.spending_stat.perform
end

desc "Import Corby Payments"
task :import_corby_payments => :environment do
  corby = Council.first(:conditions => "name LIKE '%Corby %'")
  puts "Adding transactions for Corby Council"
  periods = %w(June July)
  periods.each do |period|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/corby/#{period} 2010 published spend.csv"), :headers => true) do |csv_file|
      csv_file.each do |row|
        next if row['Section Name'].blank? #dealing with total row
        ft = FinancialTransaction.new(:date => ("13 #{period} 2010".to_date),
                                      :value => row['Net Amount'],
                                      :supplier_name => row['Creditor Name'],
                                      :supplier_uid => row['Creditor_Account_No'],
                                      :cost_centre => row['GL Code'],
                                      :department_name => row['Section_Name'],
                                      :organisation => corby,
                                      :csv_line_number => csv_file.lineno+1, #deleted headings
                                      :uid => row['Voucher No'],
                                      :source_url => "http://www.corby.gov.uk/CouncilAndDemocracy/CouncilBudgetsAndSpending/Documents/#{period}%202010%20published%20spend.csv"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  corby.spending_stat.perform
end

desc "Import GLA Payments"
task :import_gla_payments => :environment do
  gla = Council.first(:conditions => {:name => 'Greater London Authority'})
  puts "Adding transactions for #{gla.title}"
  i=0
  files = [['http://static.london.gov.uk/gla/expenditure/docs/2010-11-P03.csv', 7], ['http://static.london.gov.uk/gla/expenditure/docs/2010-11-P04-500.csv', 12]]
  files.each do |url, csv_offset|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/gla/0#{i+6}_2010.csv"), :headers => true) do |csv_file|
      puts "Adding data from #{url}"
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row['Clearing Date'],
                                      :value => row['Amount'],
                                      :supplier_name => row['Vendor Name'],
                                      :supplier_uid => row['Vendor ID'],
                                      :cost_centre => row['Expenditure Account Code'],
                                      :service => row['Expenditure Account Code Description'],
                                      # :department_name => row['Section_Name'],
                                      :organisation => gla,
                                      :csv_line_number => csv_file.lineno+csv_offset, 
                                      :uid => row['SAP Document No'],
                                      :source_url => url
                                      )
        ft.save!                                  
        puts "."
      end
    end
    i += 1
  end
  gla.spending_stat.perform
end

desc "Import South Glocs Payments"
task :import_south_glocs_payments => :environment do
  council = Council.first(:conditions => "name LIKE '%South Gloucester%'")
  puts "Adding transactions for South Glocs "
  date = "15-05-2010"
  FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/south_glos/apr_jun_2010.csv"), :headers => true) do |csv_file|
    csv_file.each do |row|
      next if row['Gross Amount'].blank?
      ft = FinancialTransaction.new(:date => date,
                                    :date_fuzziness => 40,
                                    :value => row['Gross Amount'],
                                    :supplier_name => row['Creditor Name'],
                                    :transaction_type => row['Fund Type'],
                                    :department_name => row['Dept'],
                                    :service => row['Cost Centre Description'],
                                    :description => row['Office Supplies & Equipment'],
                                    :organisation => council,
                                    :csv_line_number => csv_file.lineno,
                                    :source_url => "http://hosted.southglos.gov.uk/councilpayments/apr_jun_2010.csv"
                                    )
      ft.save!                                  
      puts "."
    end
  end
  council.spending_stat.perform
end

desc "Import Trafford Council Payments"
task :import_trafford_payments => :environment do
  council = Council.first(:conditions => "name LIKE '%Trafford%'")
  puts "Adding transactions for #{council.title}"
  date = "15-05-2010"
  Nokogiri.XML(open('http://www.trafford.gov.uk/opendata/sets/supplierspend2010Q2.xml')).search('record').each do |record|
    ft = FinancialTransaction.new(:date => date,
                                  :date_fuzziness => 40,
                                  :value => record.at('amount').inner_text,
                                  :uid => record.at('ref').inner_text,
                                  :supplier_name => record.at('supplier').inner_text,
                                  :source_url => "http://www.trafford.gov.uk/opendata/sets/supplierspend2010Q2.xml"
                                  )
      ft.save!                                  
      puts "."
  end
  council.spending_stat.perform
end

desc "Import Hillingdon Payments"
task :import_hillingdon_payments => :environment do
  council = Council.first(:conditions => "name LIKE '%Hillingdon%'")
  puts "Adding transactions for #{council.title}"
  Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'lb_hillingdon')).select{ |f| f.scan(/(\d+)\.csv/).to_s.to_i > 6 }.each do |file_name|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/lb_hillingdon/#{file_name}"), :headers => true) do |csv_file|
      puts "Importing data from #{file_name}"
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => ("14-#{row['MONTH']}-#{row['YEAR']}"),
                                      :date_fuzziness => 13,
                                      :value => row['COST'],
                                      :supplier_name => row['VENDOR'],
                                      :organisation => council,
                                      :csv_line_number => csv_file.lineno, 
                                      :service => row['DESCRIPTION'],
                                      :source_url => "http://www.hillingdon.gov.uk/html/apps/opendata.php?data=Council+expenditure&rest=year.#{row['YEAR']}/month.#{row['MONTH']}&type=csv"
                                      )
        ft.save!                                  
        puts "."
      end
    end
  end
  council.spending_stat.perform
end

desc "Import Broxbourne Payments"
task :import_broxbourne_payments => :environment do
  council = Council.first(:conditions => "name LIKE '%Broxbourne%'")
  puts "Adding transactions for #{council.title}"
  Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'broxbourne')).select{ |f| f.match('csv') }.each do |file_name|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/broxbourne/#{file_name}"), :headers => true) do |csv_file|
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row["Transaction Date"].gsub('/', '-'),
                                      :value => row['Amount'],
                                      :supplier_name => row["Supplier Name"],
                                      :uid => row["Transaction Number"],
                                      :department_name => row['Committee'],
                                      :cost_centre => row["Cost Centre"],
                                      :organisation => council,
                                      :csv_line_number => csv_file.lineno+1, #deleted title
                                      :service => row["Service Area"],
                                      :source_url => "http://www.broxbourne.gov.uk/docs/#{file_name.gsub(/csv$/,'xls')}"
                                      )
        ft.save!                                  
        puts "."
      end
    end    
  end
  council.spending_stat.perform
end

desc "Import West Dorset Payments"
task :import_west_dorset_payments => :environment do
  council = Council.first(:conditions => "name LIKE '%West Dorset%'")
  puts "Adding transactions for #{council.title}"
  Dir.entries(File.join(RAILS_ROOT, 'db', 'data', 'spending', 'west_dorset')).select{ |f| f.match('csv') }.each do |file_name|
    FasterCSV.open(File.join(RAILS_ROOT, "db/data/spending/west_dorset/#{file_name}"), :headers => true) do |csv_file|
      csv_file.each do |row|
        ft = FinancialTransaction.new(:date => row["Payment Date"].gsub('/', '-'),
                                      :value => row['Amount'],
                                      :supplier_name => row["Supplier Name"],
                                      :uid => row["Voucher Number"],
                                      :organisation => council,
                                      :csv_line_number => csv_file.lineno,
                                      :service => row["Account Name"],
                                      :source_url => "http://www.dorsetforyou.com/media.jsp?mediaid=153859&filetype=doc"
                                      )
        ft.save!                                  
        puts "."
      end
    end    
  end
  council.spending_stat.perform
end


