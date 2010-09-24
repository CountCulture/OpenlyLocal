class AddMoreIndicesToCharitiesTable < ActiveRecord::Migration
  def self.up
    add_index :charities, :income
    add_index :charities, :spending
    execute("CREATE INDEX `index_charities_on_title` ON charities (title(4))")
  end

  def self.down
    execute("ALTER TABLE charities DROP INDEX `index_charities_on_title`")
    remove_index :charities, :spending
    remove_index :charities, :income
  end
end
