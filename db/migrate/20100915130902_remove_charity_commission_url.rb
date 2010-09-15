class RemoveCharityCommissionUrl < ActiveRecord::Migration
  def self.up
    remove_column :charities, :charity_commission_url
  end

  def self.down
    add_column :charities, :charity_commission_url, :string
  end
end
