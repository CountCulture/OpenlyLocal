class AddOutputAreaClassToWardsAndCouncils < ActiveRecord::Migration
  def self.up
    add_column :wards, :output_area_classification_id, :integer
    add_column :councils, :output_area_classification_id, :integer
  end

  def self.down
    remove_column :councils, :output_area_classification_id
    remove_column :wards, :output_area_classification_id
  end
end
