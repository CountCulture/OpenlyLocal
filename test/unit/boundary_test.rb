require File.expand_path('../../test_helper', __FILE__)

class BoundaryTest < ActiveSupport::TestCase
  subject { @boundary }
  
  context "The Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end
    
    should_validate_presence_of :area_id, :area_type, :boundary_line
    should have_db_column :hectares
    
    should "have associated polymorphic area" do
      @area = Factory(:council, :name => "Council with boundary")
      @boundary.area = @area
      assert_equal "Council", @boundary.area_type
      assert_equal @area.id, @boundary.area_id
    end
    
    context "when storing boundary_line" do
      should "store as Polygon" do
        assert_kind_of Polygon, @boundary.boundary_line
      end
    end    
  end
  
  context "An instance of the Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end
    
    context "when returning bounding box" do
      should "return bounding box of boundary_line" do
        assert_equal @boundary.boundary_line.bounding_box, @boundary.bounding_box
      end
    end
    
    context "when returning centrepoint" do
      should "return centre point of envelope" do
        assert_equal @boundary.boundary_line.envelope.center, @boundary.centrepoint
      end
    end    
    
    context "when returning boundary_line_coordinates" do
      setup do
        @complex_polygon = Polygon.from_coordinates([ [[1.1, 52.1], [2.1, 52.1], [2.1, 54.1], [1.1, 54.1], [1.1, 52.1]],
                                                      [[3.1, 62.1], [5.1, 62.1], [5.1, 64.1], [3.1, 64.1], [3.1, 62.1]] ])
      end

      should "return array" do
        assert_kind_of Array, @boundary.boundary_line_coordinates
      end
      
      should "return coordinates of polygon line rings" do
        expected_coords = [@boundary.boundary_line.rings.first.collect{ |point| [point.lat, point.lng] }]
        assert_equal expected_coords, @boundary.boundary_line_coordinates
      end
      
      should "return coordinates of all polygon line rings" do
        @boundary.update_attribute(:boundary_line, @complex_polygon)
        expected_coords = @complex_polygon.rings.collect{ |ring| ring.collect{ |point| [point.lat, point.lng] } }
        assert_equal expected_coords, @boundary.boundary_line_coordinates
      end
    end
  end
end
