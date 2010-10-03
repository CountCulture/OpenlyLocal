class ChangeQuangoToEntity < ActiveRecord::Migration
  def self.up
    rename_column :quangos, :quango_type, :entity_type
    rename_column :quangos, :quango_subtype, :entity_subtype
    rename_table :quangos, :entities
  end

  def self.down
    rename_column :entities, :entity_subtype, :quango_subtype
    rename_column :entities, :entity_type, :quango_type
    rename_table :entities, :quangos
  end
end
