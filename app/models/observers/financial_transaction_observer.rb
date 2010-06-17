class FinancialTransactionObserver < ActiveRecord::Observer
  def after_save(ft)
    ft.supplier.update_attribute(:total_spend, ft.supplier.calculated_total_spend)
    true
  end
  
  # def after_destroy(vehicle)
  #   User.update_all("updated_at = '#{Time.now.to_s(:db)}'", ["id=?", vehicle.user_id])
  #   true
  # end
  
end