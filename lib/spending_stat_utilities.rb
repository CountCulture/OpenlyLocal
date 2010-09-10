module SpendingStatUtilities
  module Base
    module ClassMethods
    end
    
    module InstanceMethods

      private
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
      receiver.after_create :update_spending_stat
      
    end
  end            
  
end