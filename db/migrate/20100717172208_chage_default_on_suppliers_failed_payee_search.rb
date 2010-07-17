class ChageDefaultOnSuppliersFailedPayeeSearch < ActiveRecord::Migration
  def self.up
    change_column_default :suppliers, :failed_payee_search, "0"
    Supplier.update_all("failed_payee_search = '0'", :failed_payee_search => nil)
  end

  def self.down
    change_column_default :suppliers, :failed_payee_search, nil
  end
end
