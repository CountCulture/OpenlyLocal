class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    # NB need to reload supplier, because it will think it hasn't got any financial transacrtions and therefore won't calculated spend
    # ft.supplier.update_attribute(:total_spend, ft.supplier.reload.calculated_total_spend)
    true
  end
    
end