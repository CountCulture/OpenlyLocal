module SpendingStatUtilities
  module Base
    module ClassMethods
      def cache_spending_data
        data = calculated_spending_data
        File.open(cached_spending_data_location, "w") do |f|
          f.write(data.to_yaml)
        end
        cached_spending_data_location
      end
      
      def cached_spending_data_location
        File.join(RAILS_ROOT, 'db', 'data', 'cache', "#{self.to_s.underscore}_spending")
      end
      
      def cached_spending_data
        data_file = cached_spending_data_location
        return unless basic_spending_data = YAML.load_file(data_file) rescue nil
        basic_spending_data.select{ |k,v| k.to_s.match(/^largest_/) }.each do |k,v|
          klass = k.to_s.sub(/^largest_/,'').classify.constantize rescue nil
          if klass
            basic_spending_data[k] = klass.find(basic_spending_data[k]).sort{ |a,b| basic_spending_data[k].index(a.id) <=> basic_spending_data[k].index(b.id)}
          end
        end
        basic_spending_data
      end

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
                        :earliest_transaction,
                        :latest_transaction,
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
      
      def data_for_payer_breakdown
        supplying_groups = supplying_relationships.group_by(&:organisation).sort{ |a,b| a[0].title <=> b[0].title }
        return if supplying_groups.blank?
        supplying_groups.collect do |org, srs|
          total_spend = srs.sum{ |s| s.total_spend.to_i }
          dates = srs.collect{ |s| [s.earliest_transaction, s.latest_transaction] }.flatten.compact.sort
          average_spend_per_month = (total_spend/(difference_in_months_between_dates(dates.first, dates.last)+1)).to_i rescue nil
          subtotal = [org, total_spend, average_spend_per_month]
          [org, {:elements => srs, :subtotal => subtotal}]
        end
      end
      
      private
      def update_associated_spending_stats(supplier)
        supplier.update_spending_stat
        supplier.organisation.update_spending_stat
        self.update_spending_stat
      end
      
      def difference_in_months_between_dates(early_date,later_date)
        (later_date.year - early_date.year) * 12 + (later_date.month - early_date.month)
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