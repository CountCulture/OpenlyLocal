require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  should_validate_presence_of :last_name, :url, :council_id
  should_belong_to :council
  should_belong_to :ward
  should_have_many :memberships
  should_have_many :candidacies
  should_have_many :committees, :through => :memberships
  should_have_many :related_articles
  should_have_named_scope :current, :conditions => "date_left IS NULL"
  should_have_db_columns :address, :blog_url, :facebook_account_name, :linked_in_account_name
  
  context "The Member class" do
    setup do
      @existing_member = Factory.create(:member)
      @params = {:full_name => "Fred Wilson", :uid => 2, :council_id => 2, :party => "Independent", :url => "http:/some.url"} # uid and council_id can be anything as we stub finding of existing member
    end
    
    should_validate_uniqueness_of :uid, :scoped_to => :council_id
    should_validate_presence_of :uid
    should "include ScraperModel mixin" do
      assert Member.respond_to?(:find_all_existing)
    end
    
    should "include TwitterAccountMethods mixin" do
      assert Member.new.respond_to?(:twitter_account_name)
    end
    
    context 'when returning excluding vacancies' do
      setup do
        @vacancy = Factory.create(:member, :full_name => "Vacancy", :council => @existing_member.council)
      end
      
      should 'return members' do
        assert Member.except_vacancies.include?(@existing_member)
      end
      
      should 'not return vacancies' do
        assert !Member.except_vacancies.include?(@vacancy)
      end
    end
    
    context "should overwrite orphan_records_callback and" do
      setup do
        @another_member = Factory(:member, :council => @existing_member.council)
        @vacancy = Factory.create(:member, :full_name => "Vacancy", :council => @existing_member.council)
      end
      
      should "notify Hoptoad of orphan records" do
        HoptoadNotifier.expects(:notify).with(has_entries(:error_class => "OrphanRecords", :error_message => regexp_matches(/2 orphan Member records/)))
        Member.send(:orphan_records_callback, [@existing_member, @another_member], :save_results => true)
      end       

      should "not notify Hoptoad of orphan records if not saving results" do
        HoptoadNotifier.expects(:notify).never
        Member.send(:orphan_records_callback, [@existing_member, @another_member])
      end       

      should "not mark orphan members as ex_members if not saving results" do      
        Member.send(:orphan_records_callback, [@existing_member, @another_member])
        assert !@existing_member.reload.ex_member?
        assert !@another_member.reload.ex_member?
      end
      
      should "not delete vacancies if not saving results" do      
        Member.send(:orphan_records_callback, [@existing_member, @vacancy])
        assert !@existing_member.reload.ex_member?
        assert Member.find_by_id(@vacancy.id)
      end
      
      should "not notify Hoptoad of orphan records if there are none" do
        HoptoadNotifier.expects(:notify).never
        Member.send(:orphan_records_callback, [], :save_results => true)
      end   

      should "not notify Hoptoad of orphan records if members already marked as ex_members" do
        @existing_member.update_attribute(:date_left, 3.days.ago)
        @another_member.update_attribute(:date_left, 5.days.ago)
        HoptoadNotifier.expects(:notify).never
        Member.send(:orphan_records_callback, [@existing_member, @another_member], :save_results => true)
      end  
           
      should "notify Hoptoad of orphan records if some members not marked as ex_member" do
        @existing_member.update_attribute(:date_left, 3.days.ago)
        
        HoptoadNotifier.expects(:notify).with(has_entries(:error_message => regexp_matches(/1 orphan Member records/)))
        Member.send(:orphan_records_callback, [@existing_member, @another_member], :save_results => true)
      end   
          
      should "mark orphan members as ex_members" do
        Member.send(:orphan_records_callback, [@existing_member, @another_member], :save_results => true)
        assert @existing_member.reload.ex_member?
        assert @another_member.reload.ex_member?
        assert_equal Date.today, @existing_member.date_left
      end  
           
      should "delete records that are vacancies" do
        Member.send(:orphan_records_callback, [@existing_member, @vacancy], :save_results => true)
        assert_nil Member.find_by_id(@vacancy.id)
        assert @existing_member.reload.ex_member?
      end       
    end
    
    context "should have latest_succesful_candidacy and" do
      setup do
        @area = Factory(:ward, :council => @existing_member.council)
        @poll = Factory(:poll, :area => @area, :date_held => 1.year.ago)
        @more_recent_poll = Factory(:poll, :area => @area, :date_held => 5.days.ago) # more recent
        @old_poll = Factory(:poll, :area => @area, :date_held => 4.years.ago)
        @candidacy = Factory(:candidacy, :votes => 321, :elected => true, :poll => @poll, :member => @existing_member)
      end
      
      should "return nil if no candidancies" do
        assert_nil Member.new.latest_succesful_candidacy
      end
      
      should "return successful candidacy" do
        assert_equal @candidacy, @existing_member.latest_succesful_candidacy
      end
      
      should "most recent successful candidacy" do
        older_candidate = Factory(:candidacy, :poll => @old_poll, :member => @existing_member, :votes => 234, :elected => true, :last_name => "Aname")
        assert_equal @candidacy, @existing_member.latest_succesful_candidacy
      end
      
      should "not return unsuccessful candidacy" do
        @candidacy.update_attribute(:elected, false)
        assert_nil @existing_member.latest_succesful_candidacy
      end
      
      should "not return no votes candidacy" do
        no_result_candidacy = Factory(:candidacy, :poll => @more_recent_poll, :member => @existing_member)
        assert_equal @candidacy, @existing_member.latest_succesful_candidacy
      end
      
    end   
      
  end
  
  context "A Member instance" do
    setup do
      @member = new_member(:full_name => "Fred Scuttle")
    end
    
    context "when parsing name" do
      setup do
        NameParser.stubs(:parse).returns(:first_name => "Fred", :last_name => "Scuttle", :name_title => "Prof", :qualifications => "PhD")
        @named_member = new_member(:full_name => "Fred Scuttle")
      end

      should "send name to parser" do
        NameParser.expects(:parse).with("Fred Scuttleman").returns(stub_everything)
        new_member(:full_name => "Fred Scuttleman")
      end

      should "return full name" do
        assert_equal "Fred Scuttle", @named_member.full_name
      end

      should "should extract first name from full name" do
        assert_equal "Fred", @named_member.first_name
      end

      should "extract last name from full name" do
        assert_equal "Scuttle", @named_member.last_name
      end

      should "extract name_title from full name" do
        assert_equal "Prof", @named_member.name_title
      end

      should "extract qualifications from full name" do
        assert_equal "PhD", @named_member.qualifications
      end

      should "alias full_name as title" do
        assert_equal @member.full_name, @named_member.title
      end
    end
    
    should "be ex_member if has left office" do
      assert new_member(:date_left => 5.months.ago).ex_member?
    end
    
    should "not be ex_member if has not left office" do
      assert !new_member.ex_member?
    end
    
    should "return status of member" do
      member = Factory(:member)
      assert_nil member.status
      member.update_attribute(:date_left, 3.days.ago)
      assert_equal "ex_member", member.status
      member.update_attribute(:full_name, "Vacancy")
      assert_equal "vacancy", member.status
    end
    
    should "return whether member is a vacancy" do
      assert new_member(:full_name => "Vacancy").vacancy?
      assert new_member(:full_name => "Vacant Seat").vacancy?
    end
    
    context "when assigning party" do
      should "store party attribute" do
        assert_equal "Conservative", new_member(:party => "Conservative")[:party]
      end

      should "normalise name via Party instance 'Party' from given party name" do
        Party.expects(:new).with("foo").returns("bar")
        assert_equal "bar", new_member(:party => "foo")[:party]
      end

      should "update existing party" do
        member = Factory(:member, :party => "Conservative")
        
        member.update_attributes(:party => "foo")
        assert_equal "foo", member.reload.party.to_s
        member.update_attributes(:party => nil)
        assert member.reload.party.blank?
      end
    end
    
    context "when returning party" do
      should "return party instance" do
        assert_kind_of Party, new_member(:party => "Conservative").party
      end

      should "return party corresponding to party name" do
        member = new_member(:party => "Conservative")
        mock_party = stub
        Party.expects(:new).with("Conservative").returns(mock_party)
        assert_equal mock_party, member.party
      end

    end
    
    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @member.foaf_telephone
      end
      
      should "return formatted number" do
        @member.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @member.foaf_telephone
      end
    end
    
    should "allow access to wards via name" do
      ward = Factory(:ward)
      ward.members << @member
      assert_equal ward.name, @member.ward_name
    end
    
    should "have no potential_meetings" do
      assert_equal [], @member.potential_meetings
    end
    
    context "when creating first member for council" do
      setup do
        @council = Factory(:council)
        @dummy_tweeter = Tweeter.new('foo')
      end
      
      should "Tweet about council being added" do
        Factory(:committee, :council => @council)
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter))
        Factory(:member, :council => @council)
      end
      
      should "not Tweet about council being added if councils has no committees" do
        Delayed::Job.expects(:enqueue).never
        Factory(:member, :council => @council)
      end
      
      context "and when tweeting" do
        setup do
          Factory(:committee, :council => @council)
        end
        
        should "message about new parsed council" do
          Tweeter.expects(:new).with(regexp_matches(/#{@council.name} has been added to OpenlyLocal/), anything).returns(@dummy_tweeter)
          Factory(:member, :council => @council)
        end

        should "include openlylocal url of council" do
          Tweeter.expects(:new).with(anything, has_entry(:url, "http://openlylocal.com/councils/#{@council.to_param}")).returns(@dummy_tweeter)
          Factory(:member, :council => @council)
        end
        
        should "include council twitter_account in message if it exists" do
          @council.update_attribute(:twitter_account_name, "anycouncil")
          Tweeter.expects(:new).with(regexp_matches(/@anycouncil/), anything).returns(@dummy_tweeter)
          Factory(:member, :council => @council)
        end

        should "not include council twitter_account in message if it has none" do
          Tweeter.stubs(:new).returns(@dummy_tweeter)
          Tweeter.expects(:new).with(regexp_matches(/@/), anything).never
          
          Factory(:member, :council => @council)
        end

        should "include council location in message if it is known" do
          @council.update_attributes(:lng => 45, :lat => 0.123)
          Tweeter.stubs(:new).returns(@dummy_tweeter)
          Tweeter.expects(:new).with(anything, has_entries(:lat => 0.123, :long => 45)).returns(@dummy_tweeter)
          
          Factory(:member, :council => @council)
        end
        
        should "not include council location in message if it has none" do
          Tweeter.stubs(:new).returns(@dummy_tweeter)
          Tweeter.expects(:new).with(anything, has_key(:lat)).never
          Tweeter.expects(:new).with(anything, has_key(:long)).never
          
          Factory(:member, :council => @council)
        end

      end
    end
    
    context "when creating member for council with other members" do
      should "Not Tweet about council being added" do
        member = Factory(:member)
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter)).never
        Factory(:member, :council => member.council)
      end
    end
    
    context "when marking as ex_member" do
      should "set date_left to current date" do
        member = Factory(:member)
        member.mark_as_ex_member
        assert_equal Date.today, member.reload.date_left
      end 
      
      should "not update date_left if already set" do
        member = Factory(:member, :date_left => 3.days.ago)
        member.mark_as_ex_member
        assert_equal 3.days.ago.to_date, member.reload.date_left
      end  
    end
    
    #twitter stuff
    should "override included twitter_list_name to return ukcouncillors" do
      assert_equal "ukcouncillors", @member.twitter_list_name
    end
    
    context "when updating from user_submission" do
      setup do
        @member = Factory(:member)
        @council = @member.council
        @user_submission = Factory(:user_submission, :council => @council, :twitter_account_name => "foo", :facebook_account_name => "baz", :linked_in_account_name => "bar", :blog_url => "http://blog.com")
      end
      
      should "update member with twitter_name" do
        @member.update_from_user_submission(@user_submission)
        assert_equal "foo", @member.reload.twitter_account_name
      end
      
      should "update member with blog_url" do
        @member.update_from_user_submission(@user_submission)
        assert_equal "http://blog.com", @member.reload.blog_url
      end
      
      should "update member with facebook_account_name" do
        @member.update_from_user_submission(@user_submission)
        assert_equal "baz", @member.reload.facebook_account_name
      end
      
      should "return true if successful" do
        assert @member.update_from_user_submission(@user_submission)
      end
      
      context "and attributes already set" do
        setup do
          @user_submission.update_attribute(:blog_url, "")
          @member.update_attribute(:blog_url, "http://foo.com")
        end
        
        should "not overwrite when user_submission values are blank" do
          @member.update_from_user_submission(@user_submission)
          assert_equal "http://foo.com", @member.reload.blog_url
        end
        
      end
    end
    
    # NB This is not really necessary any more as all management of twitter lists is handle by TwitterAccount class
    context "in managing membership of ukcouncillors twitter list" do
      setup do
        member = Factory(:member) # add member so any we add aren't the first for the council
        @council = member.council
        @dummy_tweeter = Tweeter.new('foo')
        Tweeter.stubs(:new).returns(@dummy_tweeter)
      end
      
      context "when member is added" do

        context "and member has twitter account" do
          should "add to ukcouncillors twitter list" do
            new_member = Factory.build(:member, :twitter_account_name => "foo", :council => @council)
            Tweeter.expects(:new).with(:method => :add_to_list, :user => "foo", :list => "ukcouncillors").returns(@dummy_tweeter)

            new_member.save
          end
        end 

        context "and member does not have twitter account" do
          should "not add to ukcouncillors twitter list" do
            new_member = Factory.build(:member, :council => @council)
            Tweeter.expects(:new).never
            new_member.save
          end
        end 
      end
      
      context "when member with existing twitter_account is saved" do
        
        context "and twitter account is not changed" do
          
          should "not add to twitter list" do
            existing_member = Factory(:member, :twitter_account_name => "foo", :council => @council)
            Tweeter.expects(:new).never
            new_member.save
          end
        end
        
        context "and twitter account is changed" do
          
          should "remove old account from twitter list" do
            existing_member = Factory(:member, :twitter_account_name => 'foo', :council => @council)
            Tweeter.expects(:new).with(has_entries(:method => :remove_from_list, :user => 'foo', :list => 'ukcouncillors')).returns(@dummy_tweeter)
            existing_member.update_attribute(:twitter_account_name, 'bar')
          end
          
          should "add new account to twitter list" do
            existing_member = Factory(:member, :twitter_account_name => 'foo', :council => @council)
            Tweeter.expects(:new).with(has_entries(:method => :add_to_list, :user => 'bar', :list => 'ukcouncillors')).returns(@dummy_tweeter)
            existing_member.update_attribute(:twitter_account_name, 'bar')
          end
        end
      end

      context "when existing member has twitter account added" do

        should "add account to ukcouncillors twitter list" do
          existing_member = Factory(:member, :council => @council)
          Tweeter.expects(:new).with(has_entries(:method => :add_to_list, :user => 'foo', :list => 'ukcouncillors')).returns(@dummy_tweeter)
          existing_member.update_attributes(:twitter_account_name => "foo")
        end
      end

      context "when existing member has twitter account deleted" do

        should "remove account from ukcouncillors twitter list" do
          existing_member = Factory(:member, :twitter_account_name => "foo", :council => @council)
          Tweeter.expects(:new).with(has_entries(:method => :remove_from_list, :user => 'foo', :list => 'ukcouncillors')).returns(@dummy_tweeter)
          existing_member.twitter_account.destroy
        end
      end
    end
    
    
    context "with committees" do
      # this part is mostly just regression test that allows_access_to works in same way to UidExtension
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

      should "allow access to committees via normalised_titles" do
        assert_equal [@old_committee.normalised_title], @member.committee_normalised_titles
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
