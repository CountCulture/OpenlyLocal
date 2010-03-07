require 'test_helper'

class BoundaryTest < ActiveSupport::TestCase
  subject { @boundary }
  
  context "The Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end
    
    should_validate_presence_of :bounding_box, :area_id, :area_type
    
    should "have associated polymorphic area" do
      @area = Factory(:council, :name => "Council with boundary")
      @boundary.area = @area
      assert_equal "Council", @boundary.area_type
      assert_equal @area.id, @boundary.area_id
    end
    
    context "when storing bounding box" do
      should "store as Polygon" do
        assert_kind_of Polygon, @boundary.bounding_box
      end
    end    
  end
  
  context "An instance of the Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end

    context "when setting bounding box from sw ne" do
      
      should "set bounding box to polygon using sw ne coords" do
        expected_box = Polygon.from_coordinates([[[-3.2, 39.2], [0.2, 39.2], [0.2, 42.1], [-3.2, 42.1], [-3.2, 39.2]]])
        @boundary.bounding_box_from_sw_ne = [[39.2, -3.2],[42.1, 0.2]]
        assert_equal expected_box, @boundary.bounding_box
      end
    end    
  end
end
