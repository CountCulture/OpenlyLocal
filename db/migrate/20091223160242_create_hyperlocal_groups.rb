class CreateHyperlocalGroups < ActiveRecord::Migration
  def self.up
    create_table :hyperlocal_groups do |t|
      t.string    :title
      t.string    :url
      t.string    :email
      t.timestamps
    end
    add_column :hyperlocal_sites, :hyperlocal_group_id, :integer
  end

  def self.down
    remove_column :hyperlocal_sites, :hyperlocal_group_id
    drop_table :hyperlocal_groups
  end
end
