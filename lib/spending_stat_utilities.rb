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
  
end