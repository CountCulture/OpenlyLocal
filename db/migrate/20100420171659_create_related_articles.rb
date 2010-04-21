class CreateRelatedArticles < ActiveRecord::Migration
  def self.up
    create_table :related_articles do |t|
      t.string  :title
      t.string  :url
      t.string  :subject_type
      t.integer :subject_id
      t.text    :extract
      t.integer :hyperlocal_site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :related_articles
  end
end
