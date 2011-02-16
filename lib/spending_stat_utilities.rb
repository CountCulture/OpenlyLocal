module SpendingStatUtilities
  module Base
    module ClassMethods
    end
    
    module InstanceMethods
      
      def update_spending_stat_with(fin_trans)
        create_spending_stat unless spending_stat
        spending_stat.update_from(fin_trans)
      end

      def update_spending_stat
        create_spending_stat unless spending_stat
        Delayed::Job.enqueue(spending_stat)
      end

    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.has_one :spending_stat, :as => :organisation, :dependent => :destroy
      receiver.delegate :total_spend, 
                        :average_monthly_spend, 
                        :average_transaction_value, 
                        :to => :spending_stat, 
                        :allow_nil => true      
    end
  end            
  
  module Payer
    module ClassMethods
      
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.has_many :suppliers, :as => :organisation
      receiver.has_many :payments, :through => :suppliers, :source => :financial_transactions
    end
  end
  
  module Payee
    module ClassMethods
      
    end
    
    module InstanceMethods
      
      private
      def update_associated_spending_stats(supplier)
        supplier.update_spending_stat
        supplier.organisation.update_spending_stat
        self.update_spending_stat
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.has_many :supplying_relationships, :class_name => "Supplier", :as => :payee, 
                                                  :after_add => :update_associated_spending_stats,
                                                  :after_remove => :update_associated_spending_stats
      receiver.has_many :payments_received, :through => :supplying_relationships, :source => :financial_transactions
    end
  end
end