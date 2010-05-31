class ConnvertBoundaryGeomToMultiPolygon < ActiveRecord::Migration
  def self.up
    add_column :boundaries, :boundary_line, :multi_polygon
    add_column :boundaries, :hectares, :float
  end

  def self.down
    remove_column :boundaries, :hectares
    remove_column :boundaries, :boundary_line
  end
end
