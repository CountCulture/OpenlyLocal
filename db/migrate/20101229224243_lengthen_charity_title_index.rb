class LengthenCharityTitleIndex < ActiveRecord::Migration
  def self.up
    remove_index :charities, :title
    add_index :charities, :title
  end

  def self.down
    remove_index :charities, :title
    execute("CREATE INDEX index_charities_on_title ON charities (title(4))")
  end
end