module AddressMethods
  module ClassMethods
    
  end
  
  module InstanceMethods
    def address=(address_or_params)
      if exist_address = self.full_address
        exist_address.update_attributes(:former => true)
      end
      
      case address_or_params
      when Address
        self.full_address = address_or_params
      when Hash
        create_full_address(address_or_params)
      end
    end
    
    def address
      full_address
    end
    
    def address_in_full=(raw_address=nil)
      if addr = address 
        raw_address.blank? ? addr.destroy : addr.update_attributes(:in_full => raw_address)
      else
        create_full_address(:in_full => raw_address)
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
    receiver.has_one :full_address, :class_name => "Address", :as => :addressee, :conditions => {:former => false}, :dependent => :destroy
    receiver.has_many :former_addresses, :class_name => "Address", :as => :addressee, :conditions => {:former => true}
    receiver.delegate :in_full, :to => "address", :prefix => true, :allow_nil => true
  end
end