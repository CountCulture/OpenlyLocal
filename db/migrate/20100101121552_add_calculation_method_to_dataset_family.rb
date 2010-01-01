class AddCalculationMethodToDatasetFamily < ActiveRecord::Migration
  def self.up
    add_column :ons_dataset_families, :calculation_method, :string
  end

  def self.down
    remove_column :ons_dataset_families, :calculation_method
  end
end
