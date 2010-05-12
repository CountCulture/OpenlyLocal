module AddressMethods
  module ClassMethods
    
  end
  
  module InstanceMethods
    def address_in_full=(raw_address=nil)
      if addr = address 
        raw_address.blank? ? addr.destroy : addr.update_attributes(:in_full => raw_address)
      else
        create_address(:in_full => raw_address)
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
    receiver.has_one :address, :as => :addressee, :dependent => :destroy
    receiver.accepts_nested_attributes_for :address
    receiver.delegate :in_full, :to => "address", :prefix => true, :allow_nil => true
  end
end