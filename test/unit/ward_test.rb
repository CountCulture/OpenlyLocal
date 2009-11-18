require 'test_helper'

class WardTest < ActiveSupport::TestCase
  subject { @ward }
  context "The Ward class" do
    setup do
      @ward = Factory(:ward)
    end
    
    should_validate_presence_of :name
    should_validate_uniqueness_of :name, :scoped_to => :council_id
    should_belong_to :council
    should_validate_presence_of :council_id
    should_have_many :members
    should_have_many :committees
    should_have_many :meetings, :through => :committees
    should_have_db_column :uid
    should_have_db_column :snac_id
    should_have_db_column :url
    
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
      
      should "should clean up ward name" do
        assert_equal @ward, Ward.find_existing(:name => " #{@ward.name} Ward ", :council_id => @council.id)
      end
      
    end
    
    context "when finding by postcode" do
      setup do
        
      end
      
      should "query ons site" do
        # Net:Http.expects(:get).with(match("ab1+cd2"))
        # Ward.find_by_postcode("ab1 cd2")
      end
      
      should "parser response" do
        
      end
      
      should "raise exception if no postocde found" do
        
      end
      
      should "raise exeption if bad response" do
        
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
    
    should "store name" do
      assert_equal "Footon", Ward.new(:name => "Footon").name
    end
    
    should "discard 'Ward' from given ward name" do
      assert_equal "Footon", Ward.new(:name => "Footon Ward").name
      assert_equal "Footon", Ward.new(:name => "Footon ward").name
      assert_equal "Footon", Ward.new(:name => "Footon ward  ").name
    end
    
    context "with members" do
      # this part mainly regression test that old functionality of UidAssociation extension in continued with allows_access_to
      setup do
        @member = Factory(:member, :council => @council)
        @old_member = Factory(:old_member, :council => @council)
        @another_council = Factory(:another_council)
        @another_council_member = Factory(:member, :council => @another_council, :uid => "999")
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
    
    context "with committees" do
      # this part mainly regression test that old functionality of UidAssociation extension in continued with allows_access_to
       setup do
        @committee = Factory(:committee, :council => @council)
        @old_committee = Factory(:committee, :council => @council)
        @another_council = Factory(:another_council)
        @another_council_committee = Factory(:committee, :council => @another_council)
        @ward.committees << @old_committee
      end

      should "return committee uids" do
        assert_equal [@old_committee.uid], @ward.committee_uids
      end
      
      should "replace existing committees with ones with given uids" do
        @ward.committee_uids = [@committee.uid]
        assert_equal [@committee], @ward.committees
      end
      
      should "not add members that don't exist for council" do
        @ward.committee_uids = [@another_council_committee.uid]
        assert_equal [], @ward.committees
      end

      should "allow_access_to committees via normalised_title" do
        assert_equal [@old_committee.normalised_title], @ward.committee_normalised_titles
      end
    end
  end
end
