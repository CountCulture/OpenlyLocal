require 'test_helper'

class WardTest < ActiveSupport::TestCase
  context "The Ward class" do
    setup do
      @existing_portal = Factory.create(:ward)
    end
    
    should_validate_presence_of :name
    should_validate_uniqueness_of :name, :scoped_to => :council_id
    should_belong_to :council
    should_have_many :members
  end
  
  context "A Ward instance" do
    setup do
      @ward = Factory.create(:ward)
    end

    should "alias name as title" do
      assert_equal @ward.name, @ward.title
    end
  end
end
