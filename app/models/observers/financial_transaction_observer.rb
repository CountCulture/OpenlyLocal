class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    unless ft.supplier.vat_number.blank?  || ft.supplier.payee || ft.supplier.failed_payee_search
      Delayed::Job.enqueue(SupplierUtilities::VatMatcher.new(:vat_number => ft.supplier.vat_number, :supplier => ft.supplier, :title => ft.supplier.title)) 
    end
    # ft.clear_association_cache #reload to avoid serialisation probs
    Rails.logger.info { "About to add financial_transaction to DelayedJob queue:\n#{ft.to_yaml}" }
    Delayed::Job.enqueue(FinancialTransaction.find(ft.id))# reload FinancialTransaction (nb ft.clear_association_cache or ft.rleoad should work but soesn't seem to), add financial_transaction to DelayedJob, after VatMatcher
    true
  end
    
end