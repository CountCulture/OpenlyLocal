class FinancialTransaction < ActiveRecord::Base
  belongs_to :supplier
  before_validation :save_associated_supplier
  validates_presence_of :value, :date, :supplier_id
  attr_reader :organisation
  delegate :name, :openlylocal_url, :to => :supplier, :prefix => true
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
                 [:supplier_openlylocal_id, :supplier_id],
                 [:supplier_openlylocal_url],
                 [:cost_centre],
                 [:service],
                 [:transaction_type],
                 [:invoice_number],
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
  
  def department_name=(raw_name)
    CommonMispellings.each do |mispellings,correct|
      mispellings.each do |m|
        raw_name.sub!(Regexp.new(Regexp.escape("#{m}\s")),"#{correct} ")
      end
    end 
    self[:department_name] = raw_name.squish
  end
  
  def full_description
    return unless description? || service?
    description? ? (service? ? "#{description} (#{service})": description ) : service 
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
	
	def organisation
	 supplier&&supplier.organisation||@organisation
	end
	
	# As financial transactions are often create from CSV files, we need to set supplier 
	# from supplied params, and when doing so may not not associated organisation
	def supplier_name=(name)
    self.supplier = (organisation&&organisation.suppliers.find_or_initialize_by_name(name) || Supplier.new) unless self.supplier
	  self.supplier.name = name
	end
	
	def supplier_uid=(uid)
	  self.supplier = supplier ? (supplier.uid = uid; supplier) : Supplier.new(:uid => uid)
	end

	def supplier_vat_number=(vat_number)
	  self.supplier = supplier ? (supplier.vat_number = vat_number; supplier) : Supplier.new(:vat_number => vat_number)
    # self.supplier = organisation ? (organisation.suppliers.find_by_uid(uid) || Supplier.new(:name => uid, :organisation => organisation)) : Supplier.new(:uid => uid)
    # self.supplier = supplier ? (supplier.uid = uid; supplier) : Supplier.new(:uid => uid)
	end

  def title
    (uid? ? "Transaction #{uid}" : "Transaction") + " with #{supplier.title} on #{date.to_s(:event_date)}"
  end
  
  # strips out commas and pound signs
  def value=(raw_value)
    self[:value] =
    if raw_value.is_a?(String)
      cleaned_up_value = raw_value.gsub(/£|,|\s/,'')
      cleaned_up_value.match(/^\(([\d\.]+)\)$/) ? "-#{$1}" : cleaned_up_value
    else
      raw_value
    end
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
