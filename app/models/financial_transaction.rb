class FinancialTransaction < ActiveRecord::Base
  belongs_to :supplier, :dependent => :destroy
  before_validation :save_associated_supplier
  validates_presence_of :value, :date, :supplier_id
  attr_reader :organisation
    
  CommonMispellings = { %w(Childrens Childrens') => "Children's" }
  
  def department_name=(raw_name)
    CommonMispellings.each do |mispellings,correct|
      mispellings.each do |m|
        raw_name.sub!(Regexp.new(Regexp.escape("#{m}\s")),"#{correct} ")
      end
    end 
    self[:department_name] = raw_name.squish
  end
  
  # As financial transactions are often create from CSV files, we need to set supplier 
  # organisation directly, and also org may be known after the Supplier Name, so only update supplier if org 
	def organisation=(org)
    # supplier.organisation = org if supplier
    # @organisation = org
	  if supplier 
      # p supplier,org
      # unless supplier.organisation
      # self.supplier = org.suppliers.find_from_params(:name => supplier.name, :uid => supplier.uid, :organisation => org)
      exist_supplier = org.suppliers.find_from_params(:name => supplier.name, :uid => supplier.uid, :organisation => org)
      self.supplier = exist_supplier || supplier
      self.supplier.organisation = org unless exist_supplier# end
      # p self, self.supplier
      # (supplier = org.suppliers.find_by_name(name)) unless supplier.organisation
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
    # self.supplier = organisation ? (organisation.suppliers.find_by_name(name) || Supplier.new(:name => name, :organisation => organisation)) : Supplier.new(:name => name)
    self.supplier = (organisation&&organisation.suppliers.find_or_initialize_by_name(name) || Supplier.new) unless self.supplier
	  self.supplier.name = name
	end
	
	def supplier_uid=(uid)
    # self.supplier = organisation ? (organisation.suppliers.find_by_uid(uid) || Supplier.new(:name => uid, :organisation => organisation)) : Supplier.new(:uid => uid)
	  self.supplier = supplier ? (supplier.uid = uid; supplier) : Supplier.new(:uid => uid)
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
  
  private
  def save_associated_supplier
    supplier&&supplier.save&&(self.supplier_id=supplier.id)
    # if supplier.save
    #   # p supplier, self
    #    self.supplier_id = supplier.id #update with supplier ir
    #    true
    #  else
    #    false
    # end
  end
  
end
