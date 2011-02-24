class CreateParishCouncils < ActiveRecord::Migration
  def self.up
    create_table :parish_councils do |t|
      t.text      :title
      t.text      :os_id
      t.text      :website
      t.text      :os_id
      t.text      :council_id
      t.text      :wdtk_name
      t.text      :vat_number
      t.text      :normalised_title
      t.timestamps
    end
  end

  def self.down
    drop_table :parish_councils
  end
end
