require 'test_helper'

class WardTest < ActiveSupport::TestCase
  context "The Ward class" do
    setup do
      @ward = Factory(:ward)
    end
    
    should_validate_presence_of :name
    should_validate_uniqueness_of :name, :scoped_to => :council_id
    should_belong_to :council
    should_validate_presence_of :council_id
    should_have_many :members
    should_have_db_column :uid
    
    should "include ScraperModel mixin" do
      assert Ward.respond_to?(:find_existing)
    end
    
    context "when finding existing member from params" do
      setup do
        @council = @ward.council
      end

      should "should override find_existing and instead return member which has given name and council" do
        assert_equal @ward, Ward.find_existing(:name => @ward.name, :council_id => @council.id)
      end
      
      should "should return nil when no record with given name and council" do
        assert_nil Ward.find_existing(:name => "Bar", :council_id => @council.id)
      end
      
    end
    # should "override find_existing to find by council_id and name" do
    #   
    # end
  end
  
  context "A Ward instance" do
    setup do
      @ward = Factory.create(:ward)
      @council = @ward.council
    end

    should "alias name as title" do
      assert_equal @ward.name, @ward.title
    end
    
    context "with members" do
      # this part is really just testing inclusion of uid_association extension in members association
      setup do
        @member = Factory(:member, :council => @council)
        @old_member = Factory(:old_member, :council => @council)
        @another_council = Factory(:another_council)
        @another_council_member = Factory(:member, :council => @another_council, :uid => 999)
        @ward.members << @old_member
      end

      should "return member uids" do
        assert_equal [@old_member.uid], @ward.member_uids
      end
      
      should "replace existing members with ones with given uids" do
        @ward.member_uids = [@member.uid]
        assert_equal [@member], @ward.members
      end
      
      should "not add members that don't exist for council" do
        @ward.member_uids = [@another_council_member.uid]
        assert_equal [], @ward.members
      end
    end
  end
end
