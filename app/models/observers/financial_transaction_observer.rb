class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    Delayed::Job.enqueue(ft)
    true
  end
    
end