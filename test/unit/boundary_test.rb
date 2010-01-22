require 'test_helper'

class BoundaryTest < ActiveSupport::TestCase
  subject { @boundary }
  
  context "The Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end

    should_have_db_columns :bounding_box, :area_id, :area_type
    
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
end
