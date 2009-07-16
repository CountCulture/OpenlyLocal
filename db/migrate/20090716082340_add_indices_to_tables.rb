class AddIndicesToTables < ActiveRecord::Migration
  def self.up
    add_index :committees,   :council_id
    add_index :meetings,     :council_id
    add_index :members,      :council_id
    add_index :members,      :ward_id
    add_index :datapoints,   :council_id
    add_index :datapoints,   :dataset_id
    add_index :wards,        :council_id
    remove_column :members,  :constituency
  end

  def self.down
    add_column   :members,    :constituency, :string
    remove_index :wards,      :council_id
    remove_index :datapoints, :dataset_id
    remove_index :datapoints, :council_id
    add_index    :members,    :ward_id
    add_index    :members,    :council_id
    remove_index :meetings,   :council_id
    remove_index :committees, :council_id
  end
end
