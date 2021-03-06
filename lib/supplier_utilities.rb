module SupplierUtilities
  
  class VatMatcher
    
    EntityTypesToBeMatched = %w(Charity Entity Company)
    
    attr_reader :vat_number, :title, :supplier
    def initialize(args)
      @vat_number = args[:vat_number].strip.sub(/^GB/,'')
      @title = args[:title]
      @supplier_id = args[:supplier].id
    end
    
    # Because VatMatchers will be usually used in the context of a Delayed::Job, 
    # we can't store supplier as an instance variable, as when VatMatcher is 
    # deserialized it prob won't be deserialized properly, or at least wil have 
    # unintended consequwences
    def supplier
      @supplier = Supplier.find(@supplier_id)
    end
    
    # Finds matching entity from a variety of models. Entity returned will match VAT number and title, or normalised title if model has normalised titles
    def find_entity
      match = nil
      EntityTypesToBeMatched.each do |ent_type|
        ent_class = ent_type.constantize
        match = ent_class.new.respond_to?(:normalised_title) ? 
                      ent_class.find_by_vat_number_and_normalised_title(vat_number, ent_class.normalise_title(title)) : 
                      ent_class.find_by_vat_number_and_title(vat_number, title)
        break if match
      end
      match
    end
    
    # Try to match info based on title and vat number when we've been unable to match with existing records
    def match_using_external_data
      entity_info = !Company.probable_company?(title)&&CompanyUtilities::Client.new.get_vat_info(vat_number)||{}
      @title = entity_info[:title] || @title
      if Company.probable_company?(title)
        entity_info = CompanyUtilities::Client.new.find_company_by_name(title)
        entity = entity_info && Company.match_or_create(entity_info.merge(:vat_number => vat_number))
      else
        entity = find_entity #try to find among existing entities
      end
      entity ? supplier.update_attribute(:payee, entity) : alert_re_matching_failure 
    end
    
    def perform
      if payee = supplier.payee
        old_vat_number = payee.vat_number
        payee.update_attribute(:vat_number, vat_number)
        AdminMailer.deliver_admin_alert!( :title => "Changed vat number for supplying entity from #{vat_number}", 
                                          :details => "Vat Matcher for #{title} failed to match an entity. Supplier details\n#{supplier.inspect}"
                                          ) if !old_vat_number.blank? && old_vat_number != vat_number
      elsif entity = find_entity
        supplier.update_attribute(:payee, entity)
      else
        match_using_external_data
      end
    end
    
    private
    def alert_re_matching_failure
      AdminMailer.deliver_admin_alert!( :title => "Failed to match entity with VAT number #{vat_number}", 
                                        :details => "Vat Matcher for #{title} failed to match an entity. Supplier details\n#{supplier.inspect}")
      
    end
  end

  class CompanyNumberMatcher
    attr_reader :company_number, :supplier
    def initialize(args)
      @company_number = args[:company_number] #nb we don't need to normalise as Company class does that when matching or creating 
      @supplier_id = args[:supplier].id
    end
    
    # Because CompanyNumberMatchers will be usually used in the context of a Delayed::Job, 
    # we can't store supplier as an instance variable, as when CompanyNumberMatcher is 
    # deserialized it prob won't be deserialized properly, or at least may have 
    # unintended consequences
    def supplier
      @supplier = Supplier.find(@supplier_id)
    end
    
    def perform
      if supplier.payee
        return if Company.normalise_company_number(supplier.payee.company_number) == Company.normalise_company_number(company_number) # note we have to normalis both submitted company number and payee company number, as payee may be charity 
        AdminMailer.deliver_admin_alert!( :title => "Submitted company_number (#{@company_number}) does not match existing company number", 
                                          :details => "Given company_number for #{supplier.title} (#{supplier.organisation.title}) does not to match existing company_number (#{supplier.payee.company_number}). \nSupplier details\n#{supplier.inspect}")
        
      elsif company = Company.match_or_create(:company_number => @company_number)
        supplier.update_attribute(:payee, company)
      else
        AdminMailer.deliver_admin_alert!( :title => "No matching company found for company_number (#{@company_number})", 
                                          :details => "Given company_number for #{supplier.title} (#{supplier.organisation.title}) does not to match a UK company. \nSupplier details\n#{supplier.inspect}")
        
      end
    end
    
    
  end
end