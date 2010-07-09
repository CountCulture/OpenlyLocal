class CreateInvestigations < ActiveRecord::Migration
  def self.up
    create_table :investigations do |t|
      t.string :uid
      t.string :url
      t.string :organisation_name
      t.text :raw_html
      t.string :standards_body
      t.string :title
      t.string :subjects
      t.date :date_received
      t.date :date_completed
      t.text :allegation
      t.text :result
      t.text :case_details
      t.timestamps
    end
  end

  def self.down
    drop_table :investigations
  end
end
