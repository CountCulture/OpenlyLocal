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