class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    unless ft.supplier.vat_number.blank?  || ft.supplier.payee || ft.supplier.failed_payee_search
      Delayed::Job.enqueue(SupplierUtilities::VatMatcher.new(:vat_number => ft.supplier.vat_number, :supplier => ft.supplier, :title => ft.supplier.title)) 
    end
    ft.reload #reload to avoid serialisation probs
    Delayed::Job.enqueue(ft) # add financail_transaction to DelayedJob, after VatMatcher
    true
  end
    
end