require "test_helper"

class PartyBreakdownTestModel# <ActiveRecord::Base
  attr_accessor :members
  include PartyBreakdown
  # set_table_name "councils"
end

class PartyBreakdownTest < ActiveSupport::TestCase
  
  context "A class that includes ScrapedModel mixin" do
    setup do
      @test_model = PartyBreakdownTestModel.new
    end

    context "when returning party breakdown" do

      should "return empty array if no members" do
        @test_model.members = [] # members will normally be an AR asociation so will return empty array if no members
        assert_equal [], @test_model.party_breakdown
      end
  
      should "calculate breakdown from members list" do
        @test_model.members = party_breakdown_array("Conservative" => 3, "Labour" => 6, "Independent" => 1)
        assert_equal [[Party.new("Labour"), 6], [Party.new("Conservative"), 3],[Party.new("Independent"), 1]], @test_model.party_breakdown
      end
        
      should "return empty array if no party details for any members" do
        @test_model.members = party_breakdown_array(nil => 3)
        assert_equal [], @test_model.party_breakdown
      end
        
      should "return 'not known' for members with no party" do
        @test_model.members = party_breakdown_array("Conservative" => 3, nil => 1)
        assert_equal [[Party.new("Conservative"), 3],[Party.new("Not known"), 1]], @test_model.party_breakdown
      end
        
      should "return 'not known' for members with blank party" do
        @test_model.members = party_breakdown_array("Conservative" => 3, "" => 1)
        assert_equal [[Party.new("Conservative"), 3],[Party.new("Not known"), 1]], @test_model.party_breakdown
      end
        
      should "return 'not known' for members with blank and nil parties" do
        @test_model.members = party_breakdown_array("Conservative" => 3, nil => 1, "" => 1)
        assert_equal [[Party.new("Conservative"), 3],[Party.new("Not known"), 2]], @test_model.party_breakdown
      end
    end
    
    context "when returning party_in_control" do
      
      should "get party breakdown" do
        @test_model.expects(:party_breakdown).returns([])
        @test_model.party_in_control
      end
      
      should "return nil if no members" do
        @test_model.stubs(:party_breakdown).returns([])
        assert_nil @test_model.party_in_control
      end
      
      should "return party with majority" do
        party_breakdown = [[Party.new("Labour"), 6], [Party.new("Conservative"), 3],[Party.new("Independent"), 1]]
        @test_model.stubs(:party_breakdown).returns(party_breakdown)
        assert_equal Party.new("Labour"), @test_model.party_in_control
      end
      
      should "return 'No Overall' string if no majority party" do
        party_breakdown = [[Party.new("Labour"), 2], [Party.new("Conservative"), 3],[Party.new("Independent"), 1]]
        @test_model.stubs(:party_breakdown).returns(party_breakdown)
        assert_equal "No Overall", @test_model.party_in_control
      end
    end
      
  end
  private
  def party_breakdown_array(hsh={})
    hsh.collect do |k,v|
      (1..(v.to_i)).collect do |i|
        Member.new(:party => k)
      end
    end.flatten.compact
  end
end