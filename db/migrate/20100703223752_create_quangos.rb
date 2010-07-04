class CreateQuangos < ActiveRecord::Migration
  def self.up
    create_table :quangos do |t|
      t.string :title
      t.string :quango_type
      t.string :quango_subtype
      t.string :website
      t.string :wikipedia_url
      t.string :sponsoring_organisation
      t.string :wdtk_name
      t.text :previous_names
      t.date :setup_on
      t.date :disbanded_on
      t.timestamps
    end
  end

  def self.down
    drop_table :quangos
  end
end
