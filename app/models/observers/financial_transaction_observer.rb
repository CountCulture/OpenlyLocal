class FinancialTransactionObserver < ActiveRecord::Observer
  def after_create(ft)
    # unless ft.supplier.company_number.blank? || ft.supplier.payee || ft.supplier.failed_payee_search
    #   Delayed::Job.enqueue(SupplierUtilities::CompanyNumberMatcher.new(:company_number => ft.supplier.company_number, :supplier => ft.supplier)) 
    # end
    # unless ft.supplier.vat_number.blank? || ft.supplier.payee || ft.supplier.failed_payee_search
    #   Delayed::Job.enqueue(SupplierUtilities::VatMatcher.new(:vat_number => ft.supplier.vat_number, :supplier => ft.supplier, :title => ft.supplier.title)) 
    # end
    FinancialTransaction.find(ft.id).delay.perform # reload FinancialTransaction (nb ft.clear_association_cache or ft.rleoad should work but soesn't seem to), add financial_transaction to DelayedJob, after VatMatcher
    true
  end
  
  def after_destroy(ft)
    ft.supplier.update_spending_stat
    ft.supplier.organisation.update_spending_stat
    ft.supplier.payee.update_spending_stat if ft.supplier.payee
    true
  end
    
end