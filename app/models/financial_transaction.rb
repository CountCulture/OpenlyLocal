class FinancialTransaction < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :classification
  has_many :wdtk_requests, :as => :related_object
  before_validation :save_associated_supplier
  validates_presence_of :value, :date, :supplier_id
  attr_reader :organisation
  delegate :name, :openlylocal_url, :uid, :to => :supplier, :prefix => true
  delegate :name, :id, :openlylocal_url, :to => :organisation, :prefix => :organisation
  delegate :organisation_type, :to => :supplier
    
  CommonMispellings = { %w(Childrens Childrens') => "Children's" }
  
  # Maps CSV headings to attributes. If same then only one entry
  CsvMappings = [[:openlylocal_id, :id],
                 [:openlylocal_url],
                 [:transaction_id, :uid],
                 [:source_url],
                 [:csv_line_number],
                 [:date],
                 [:date_fuzziness],
                 [:value, :value_to_two_dec_places],
                 [:organisation_name],
                 [:organisation_openlylocal_id, :organisation_id],
                 [:organisation_type],
                 [:organisation_openlylocal_url],
                 [:supplier_name],
                 [:supplier_id, :supplier_uid],
                 [:supplier_openlylocal_id, :supplier_id],
                 [:supplier_openlylocal_url],
                 [:cost_centre],
                 [:service],
                 [:transaction_type],
                 [:invoice_number],
                 [:invoice_date],
                 [:department_name],
                 [:description],
                 # [:openlylocal_company_id],
                 # [:openlylocal_company_url],
                 # [:company_number],
                 [:created_at],
                 [:updated_at]]
  
  def self.csv_headings
    CsvMappings.map(&:first)
  end
  
  def self.build_or_update(params_array, options={})
    # p params_array
    organisation = options[:organisation]||options[:council] 
    params_array.collect do |params|
      logger.debug { "About to build or update FinancialTransaction with #{params.inspect}" }#, organisation
      ft = FinancialTransaction.new(params.merge(:organisation => organisation))
      options[:save_results] ? ft.save_without_losing_dirty : ft.valid?
      ScrapedObjectResult.new(ft)
    end
  end
  
  def self.export_spending_data
    require 'zip/zipfilesystem'
    dir = File.join(RAILS_ROOT, "db/data/downloads/")
    logger.info {"*** About to start exporting spending data to CSV file"}
    csv_file = File.join(dir, "spending.csv")
    Dir.mkdir(dir) unless File.directory?(dir)
    FasterCSV.open(csv_file, "w") do |csv|
      csv << (headings = FinancialTransaction::CsvMappings.collect{ |m| m.first })
      FinancialTransaction.find_each do |financial_transaction|
        csv << financial_transaction.csv_data
      end
    end
    logger.info {"*** Finished exporting spending data to CSV file"}

    Zip::ZipFile.open("#{csv_file}.new.zip", Zip::ZipFile::CREATE) {
      |zipfile|
      zipfile.add('spending.csv', csv_file)
    }
    logger.info {"*** Finished zipping spending CSV file: #{csv_file}.new.zip"}
    File.delete(csv_file)
    FileUtils.mv "#{csv_file}.new.zip", "#{csv_file}.zip", :force => true
    logger.info {"*** Finished process. New spending data file is at: #{csv_file}.zip"}
    # FileUtils.chmod_R 0644, "#{csv_file}.zip"
  end
  
  def averaged_date_and_value
    return [[date, value]] unless date_fuzziness?
    first_date, last_date = (date - date_fuzziness), (date + date_fuzziness)
    if (first_date.month == last_date.month) && (first_date.year == last_date.year)
      [[date, value]] 
    else
      month_span = difference_in_months_between_dates(first_date, last_date)
      average = value/(month_span+1)
      (0..month_span).collect{ |i| [first_date.advance(:months => i), average] }
    end
  end
  
  def csv_data
    CsvMappings.collect do |m|
      val = self.send(m.last)
      case val
      when Time
        val.iso8601
      when Date
        val.to_s(:db)
      else
        val
      end
    end
  end
  
  # Convert UK dates using slashes (e.g. 26/03/2010) to dates that will be converted correctly (e.g. 26-03-2010)
  def date=(raw_date)
    self[:date] = 
    if raw_date.is_a?(String)
      cleaned_up_date = raw_date.squish.match(/^\d+\/[\d\w]+\/\d+$/) ? raw_date.gsub('/','-') : raw_date
      cleaned_up_date.sub(/(\w{3}-)([01]\d)$/,'\120\2').sub(/(\w{3}-)([9]\d)$/,'\119\2')
    else
      raw_date
    end
  end
  
  def department_name=(raw_name)
    return if (name = NameParser.strip_all_spaces(raw_name)).blank?
    CommonMispellings.each do |mispellings,correct|
      mispellings.each do |m|
        name.sub!(Regexp.new(Regexp.escape("#{m}\s")),"#{correct} ")
      end
    end 
    self[:department_name] = name.squish
  end
  
  def foi_message_body
    m_body = "Under the Freedom of Information Act 2000 I would like to request the following information:\n\n"
    m_body += "All documents relating to the following payment, including (but not limited to) purchase orders, invoices, contracts, and tender document\n\n"
    m_body += "Supplier: #{supplier_name}\n"
    m_body += "Date/period: #{DateFuzzifier.date_with_fuzziness(date, date_fuzziness)}\n"  if date?
    m_body += "Transaction id: #{uid}\n" if uid?
    m_body += "Amount: £#{value}\n"
    m_body += "Data from: #{source_url}\n" if source_url
    m_body += "\nIf this information is held by an outside contractor then it is your responsibility under the FOIA to obtain that information.\n\n" + 
                "If the arrangements for any of the agreements with the Publisher have been delegated or passed onto another public body, please can you inform me of this and if possible transfer the request to that public body. My preferred format to receive this information is by electronic means, specifically in a machine-readable form (e.g. CSV, Word or Excel Documents rather than scans of printouts)." + 
                "\n\nIf you need any clarification of this request or if it is too broad in any way please feel free to email me. If some parts of this request are more difficult to answer than others please release the answerable material as it is available rather than hold up the entire request for the contested data.\n\nIf FOI requests of a similar nature have already been asked could you please include your responses to those requests. I would be grateful if you could confirm in writing that you have received this request, and I look forward to hearing from you within the 20-working day statutory time period.\n"
  	
  end
  
  def full_description
    return unless description? || service?
    description? ? (service? ? "#{description} (#{service})": description ) : service 
  end
  
  def new_record_before_save?
    instance_variable_get(:@new_record_before_save)
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/financial_transactions/#{to_param}"
  end

  # As financial transactions are often create from CSV files, we need to set supplier 
  # organisation directly, and also org may be known after the Supplier Name, so only update supplier if org 
	def organisation=(org)
	  if supplier 
      exist_supplier = org.suppliers.find_from_params(:name => supplier.name, :uid => supplier.uid, :organisation => org)
      self.supplier = exist_supplier || supplier
      self.supplier.organisation = org unless exist_supplier
    else
      @organisation = org
    end
	end
	
  # taken from ScrapedModel mixin
	def organisation
	  supplier&&supplier.organisation||@organisation
	end
	
  # convenience method for assigning Proclass classification
	def proclass10_1=(raw_class)
 	  self.proclass = raw_class, 'Proclass10.1'
	end
	
	def proclass8_3=(raw_class)
	  self.proclass = raw_class, 'Proclass8.3'
	end
	
	def proclass=(args)
	  return if args.first.blank?
	  grouping = args[1]
	  conditions = args.first.match(/^\d+$/) ? {:uid  => args.first} : {:title => args.first}
 	  pc = Classification.first(:conditions => conditions.merge(:grouping => grouping))
 	  self.classification = pc
	end
	
  # returns related transactions, i.e. same supplying relationship (default ten)
	def related(options={})
	  supplier.financial_transactions.all(:order => 'date DESC', :limit => 11) - [self]
	end
	
  # taken from ScrapedModel mixin
  def save_without_losing_dirty
    ch_attributes = changed_attributes.clone
    success = save 
    changed_attributes.update(ch_attributes) # so merge them back in
    success # return result of saving
  end

	# As financial transactions are often create from CSV files, we need to set supplier 
	# from supplied params, and when doing so may not not associated organisation
	def supplier_name=(name)
    self.supplier = (organisation&&organisation.suppliers.find_or_initialize_by_name(name) || Supplier.new) unless self.supplier
    self.supplier.name = name
	end
	
	def supplier_uid=(uid)
	  return if uid.blank?
    self.supplier = (organisation&&organisation.suppliers.find_or_initialize_by_uid(uid) || Supplier.new) unless self.supplier
    self.supplier.uid = uid
    # self.supplier = supplier ? (supplier.uid = uid; supplier) : Supplier.new(:uid => uid)
	end

	def supplier_vat_number=(vat_number)
	  self.supplier = supplier ? (supplier.vat_number = vat_number; supplier) : Supplier.new(:vat_number => vat_number)
    # self.supplier = organisation ? (organisation.suppliers.find_by_uid(uid) || Supplier.new(:name => uid, :organisation => organisation)) : Supplier.new(:uid => uid)
    # self.supplier = supplier ? (supplier.uid = uid; supplier) : Supplier.new(:uid => uid)
	end

  def title
    (uid? ? "Transaction #{uid}" : "Transaction") + " with #{supplier&&supplier.title} " + (date_fuzziness? ? "in #{DateFuzzifier.date_with_fuzziness(date, date_fuzziness)}" : "on #{date&&date.to_s(:event_date)}")
  end
  
  # strips out commas and pound signs
  def value=(raw_value)
    self[:value] = TitleNormaliser.normalise_financial_sum(raw_value)
  end

  def value_to_two_dec_places
    value && ("%.2f" % value)
  end
  
  private
  def save_associated_supplier
    supplier&&supplier.save&&(self.supplier_id=supplier.id)
  end
  
  def difference_in_months_between_dates(early_date,later_date)
    (later_date.year - early_date.year) * 12 + (later_date.month - early_date.month)
  end
end
