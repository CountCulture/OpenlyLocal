class AddCrimeLevelEtcToCrimeArea < ActiveRecord::Migration
  def self.up
    add_column :crime_areas, :crime_mapper_url, :string
    add_column :crime_areas, :feed_url, :string
    add_column :crime_areas, :crime_level_cf_national, :string
    add_column :crime_areas, :crime_rates, :text
    add_column :crime_areas, :total_crimes, :text
  end

  def self.down
    remove_column :crime_areas, :total_crimes
    remove_column :crime_areas, :crime_rates
    remove_column :crime_areas, :crime_level_cf_national
    remove_column :crime_areas, :feed_url
    remove_column :crime_areas, :crime_mapper_url
  end
end
