require 'test_helper'

class BoundaryTest < ActiveSupport::TestCase
  subject { @boundary }
  
  context "The Boundary class" do
    setup do
      @boundary = Factory(:boundary)
    end
    
    should_validate_presence_of :area_id, :area_type, :boundary_line
    should_have_db_columns :hectares
    
    should "have associated polymorphic area" do
      @area = Factory(:council, :name => "Council with boundary")
      @boundary.area = @area
      assert_equal "Council", @boundary.area_type
      assert_equal @area.id, @boundary.area_id
    end
    
    context "when storing boundary_line" do
      should "store as MultiPolygon" do
        assert_kind_of MultiPolygon, @boundary.boundary_line
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
    
  end
end
