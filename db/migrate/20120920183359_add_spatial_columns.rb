class AddSpatialColumns < ActiveRecord::Migration
  def self.up
    add_column :postcodes, :geom, :point, :srid => 4326
    add_column :hyperlocal_sites, :geom, :point, :srid => 4326

    add_index :postcodes, :geom, :spatial => true
    add_index :hyperlocal_sites, :geom, :spatial => true

    # Run separately:
    # Postcode.all.each do |record|
    #   record.update_attribute :geom, Point.from_x_y(record.lng, record.lat, 4326)
    # end
    # HyperlocalSite.all.each do |record|
    #   record.update_attribute :geom, Point.from_x_y(record.lng, record.lat, 4326)
    # end

    # addresses seems to not use its lat/lng.
    # councils seems to use its lat/lng only for tweets.
    # feed_entries seems to use its lat/lng only to link to maps.
    # police_teams seems to not populate its lat/lng columns.
  end

  def self.down
    remove_column :postcodes, :geom
    remove_column :hyperlocal_sites, :geom
  end
end
