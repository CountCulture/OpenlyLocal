require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  should_validate_presence_of :last_name, :url, :council_id
  should_belong_to :council
  should_belong_to :ward
  should_have_many :memberships
  should_have_many :committees, :through => :memberships
  should_have_named_scope :current, :conditions => "date_left IS NULL"
  should_have_db_column :address
  
  context "The Member class" do
    setup do
      @existing_member = Factory.create(:member)
      @params = {:full_name => "Fred Wilson", :uid => 2, :council_id => 2, :party => "Independent", :url => "http:/some.url"} # uid and council_id can be anything as we stub finding of existing member
    end
    
    should_validate_uniqueness_of :uid, :scoped_to => :council_id
    should_validate_presence_of :uid
    should "include ScraperModel mixin" do
      assert Member.respond_to?(:find_existing)
    end
                
  end
  
  context "A Member instance" do
    setup do
      NameParser.stubs(:parse).returns(:first_name => "Fred", :last_name => "Scuttle", :name_title => "Prof", :qualifications => "PhD")
      @member = new_member(:full_name => "Fred Scuttle")
    end
    
    should "return full name" do
      assert_equal "Fred Scuttle", @member.full_name
    end
    
    should "should extract first name from full name" do
      assert_equal "Fred", @member.first_name
    end
    
    should "extract last name from full name" do
      assert_equal "Scuttle", @member.last_name
    end
    
    should "extract name_title from full name" do
      assert_equal "Prof", @member.name_title
    end
    
    should "extract qualifications from full name" do
      assert_equal "PhD", @member.qualifications
    end
    
    should "alias full_name as title" do
      assert_equal @member.full_name, @member.title
    end
    
    should "be ex_member if has left office" do
      assert new_member(:date_left => 5.months.ago).ex_member?
    end
    
    should "not be ex_member if has not left office" do
      assert !new_member.ex_member?
    end
    
    should "store party attribute" do
      assert_equal "Conservative", new_member(:party => "Conservative").party
    end
    
    should "discard 'Party' from given party name" do
      assert_equal "Conservative", new_member(:party => "Conservative Party").party
      assert_equal "Conservative", new_member(:party => "Conservative party").party
    end
    
    should "strip extraneous spaces from given party name" do
       assert_equal "Conservative", new_member(:party => "  Conservative ").party
     end
     
    should "strip extraneous spaces and 'Party' from given party name" do
      assert_equal "Liberal Democrat", new_member(:party => "  Liberal Democrat Party ").party
    end

    should "not raise exception when party is nil" do
      assert_nothing_raised(Exception) { new_member(:party => nil) }
    end

    should "have no potential_meetings" do
      assert_equal [], @member.potential_meetings
    end
    
    context "when creating first member for council" do
      should "Tweet about council being added" do
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter))
        member = Factory(:member)
      end
    end
    
    context "when creating member for council with other members" do
      should "Not Tweet about council being added" do
        member = Factory(:member)
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter)).never
        Factory(:member, :council => member.council)
      end
    end
    
    context "with committees" do
      # this part is mostly just testing inclusion of uid_association extension in committees association
      setup do
        @member = Factory(:member)
        @council = @member.council
        @another_council = Factory(:another_council)
        @old_committee = Factory(:committee, :council => @council)
        @new_committee = Factory(:committee, :council => @council, :title => "new committee")
        @another_council_committee = Factory(:committee, :council => @another_council, :title => "another council committee")
        @member.committees << @old_committee
      end

      should "return committee uids" do
        assert_equal [@old_committee.uid], @member.committee_uids
      end
      
      should "replace existing committees with ones with given uids" do
        @member.committee_uids = [@new_committee.uid]
        assert_equal [@new_committee], @member.committees
      end
      
      should "not add committees with that don't exist for council" do
        @member.committee_uids = [@another_council_committee.uid]
        assert_equal [], @member.committees
      end
      
      context "and meetings" do
        setup do
          @member.committees << @new_committee # make sure member has two committees
          @member_meeting = Factory(:meeting, :committee => @old_committee, :council => @council, :date_held => 10.days.from_now)
          @member_meeting_2 = Factory(:meeting, :committee => @old_committee, :council => @council, :date_held => 2.days.from_now)
          @another_committee_meeting = Factory(:meeting, :committee => @new_committee, :council => @council)
          @non_member_meeting = Factory(:meeting, :committee => @another_council_committee, :council => @council)
        end

        should "have many potential_meetings" do
          assert_equal [@another_committee_meeting, @member_meeting_2, @member_meeting], @member.potential_meetings
        end

        should "have many forthcoming_meetings" do
          assert_equal [@member_meeting_2, @member_meeting], @member.forthcoming_meetings
        end
      end
      
   end
    
    context "with council" do
      setup do
        @member = Factory(:member)
        @council = @member.council
        Council.record_timestamps = false # update timestamp without triggering callbacks
        @council.update_attributes(:updated_at => 2.days.ago) #... though thought from Rails 2.3 you could do this without turning off timestamps
        Council.record_timestamps = true
      end
      context "when member is updated" do
        setup do
          @member.update_attribute(:last_name, "Wilson")
        end

        should "mark council as updated" do
          assert_in_delta Time.now, @council.updated_at, 2
        end
      end
      context "when member is deleted" do
        setup do
          @member.destroy
        end

        should "mark council as updated" do
          assert_in_delta Time.now, @council.updated_at, 2
        end
      end
      
    end
    
  end
  
  
  private
  def new_member(options={})
    Member.new(options)
  end
end
