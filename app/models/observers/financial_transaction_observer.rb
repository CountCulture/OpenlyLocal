class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    Delayed::Job.enqueue(ft.supplier.spending_stat)
    true
  end
    
end