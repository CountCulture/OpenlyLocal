require File.expand_path('../../test_helper', __FILE__)

class PollTest < ActiveSupport::TestCase
  subject { @poll }
  def setup
    @council = Factory(:council)
    @another_council = Factory(:another_council)
    @poll = Factory(:poll, :area => @council)
    @ward_1 = Factory(:ward, :council => @council, :snac_id => '41UDGE')
    @ward_2 = Factory(:ward, :council => @council, :name => 'No Snac Id ward')
    @ward_3 = Factory(:ward, :council => @council, :snac_id => '41UDPQ', :name => 'Uncontested ward')
    @another_council_ward = Factory(:ward, :council => @another_council, :snac_id => '41UDXX', :name => 'Wrong Snac id ward')
    @conservative_party = Factory(:political_party, :title => 'Conservative', :electoral_commission_uid => 25)
  end
  
  context "The Poll class" do
    
    should validate_presence_of :date_held
    [:area_id, :area_type].each do |attribute|
      should validate_presence_of attribute
    end
    should validate_presence_of :position
    [:electorate, :ballots_issued, :ballots_rejected, :postal_votes, :uncontested, :source, :ballots_missing_official_mark, :ballots_with_too_many_candidates_chosen, :ballots_with_identifiable_voter, :ballots_void_for_uncertainty].each do |column|
      should have_db_column column
    end
    should have_many(:candidacies).dependent :destroy
    should have_many :related_articles
                                                          
    should "have associated polymorphic area" do
      assert_equal @council.id, @poll.area_id
      assert_equal "Council", @poll.area_type
    end
    
    should 'return false for uncontested elected by default' do
      assert !@poll.uncontested
    end
    
    context "when returning associated_with_council named scope" do
      setup do
        @ward_poll = Factory(:poll, :area => @ward_1, :date_held => 1.year.ago)
        @another_council_poll = Factory(:poll, :area => @another_council)
        @another_council_ward_poll = Factory(:poll, :area => @another_council_ward)
        @associated_polls = Poll.associated_with_council(@council)
      end

      should 'include polls for council' do
        assert @associated_polls.include?(@poll)
      end

      should 'include polls for council wards' do
        assert @associated_polls.include?(@ward_poll)
      end

      should 'not include polls for other councils' do
        assert !@associated_polls.include?(@another_council_poll)
      end

      should 'not include polls for other wards' do
        assert !@associated_polls.include?(@another_council_ward_poll)
      end

      should 'return in date_held order, most recent first' do
        assert_equal @poll, @associated_polls.first
      end
      
      should 'return all polls when no council' do
        assert_equal Poll.all, Poll.associated_with_council(nil)
      end

    end
    
    context 'when converting all records to csv' do
      setup do
        @csv_data = Poll.to_csv
      end
      
      should 'use attributes as header row' do
        assert_match /^#{Poll::CsvFields.join(',')}/, @csv_data
      end
      
      should 'use date on subsequent rows' do
        assert_match /\n#{@poll.id},#{@council.resource_uri},/, @csv_data
      end
    end
    
    context 'when creating or updating from open_election_data' do
      setup do
        @dummy_response = 
        [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
          :source => 'http://anytown.gov.uk/elections/poll/foo',
          :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
          :date => '2007-05-03', 
          :electorate => '4409', 
          :ballots_issued => '1642', 
          :ballots_rejected => '31', 
          :uncontested => nil, 
          :candidacies => [{:given_name => 'Margaret', 
                            :family_name => 'Stanhope',
                            :votes => '790',
                            :elected => 'true',
                            :party => 'http://openelectiondata.org/id/parties/25',
                            :independent => nil },
                           {:name => 'John Linnaeus Middleton', 
                            :votes => '342',
                            :elected => 'false',
                            :party => nil,
                            :independent => true }
            ] }]
      end
      
      should 'create poll' do
        assert_difference "Poll.count", 1 do
          Poll.from_open_election_data(@dummy_response, :council => @council)
        end
      end
      
      should 'raise exception if no council given' do
        assert_raise(ArgumentError) { Poll.from_open_election_data(@dummy_response) }
      end
      
      should 'return created polls' do
        polls = Poll.from_open_election_data(@dummy_response, :council => @council)
        assert_kind_of Poll, poll = polls.first
        assert_equal '41UDGE', poll.area.snac_id
        assert_equal '2007-05-03'.to_date, poll.date_held
      end
      
      context 'and when creating poll' do
        context 'in general' do
          setup do
            @old_candidacy_count = Candidacy.count
            Poll.from_open_election_data(@dummy_response, :council => @council)
            @new_poll = Poll.last(:order => 'id')
            @new_candidacies = Candidacy.all(:order => 'id DESC', :limit => 2)
            @independent_candidacy = @new_candidacies.detect{ |c| c.votes.to_s == '342' }
            @conservative_candidacy = @new_candidacies.detect{ |c| c.votes.to_s == '790' }
          end
        
          should 'associate poll with ward associated with SNAC URI' do
            assert_equal @ward_1, @new_poll.area
          end
        
          should 'assume position is Member' do
            assert_equal 'Member', @new_poll.position
          end
        
          should 'not mark uncontested poll as uncontested' do
            assert_equal false, @new_poll.uncontested
          end
        
          should 'mark candidate as elected only when elected' do
            assert !@independent_candidacy.elected
            assert @conservative_candidacy.elected
          end
        
          should 'create with given attributes' do
            assert_equal '2007-05-03'.to_date, @new_poll.date_held
            assert_equal 4409, @new_poll.electorate 
            assert_equal 1642, @new_poll.ballots_issued
            assert_equal 31, @new_poll.ballots_rejected
            assert_equal 'http://anytown.gov.uk/elections/poll/foo', @new_poll.source
          end
        
          should 'create candidacies' do
            assert_equal @old_candidacy_count+2, Candidacy.count
          end
        
          should 'associate candidacies with poll' do
            assert @new_candidacies.all?{ |c| c.poll == @new_poll }
          end
        
          should 'parse candidacy names when necessary' do
            assert_equal 'John Linnaeus', @independent_candidacy.first_name
            assert_equal 'Middleton', @independent_candidacy.last_name
            assert_equal 'Margaret', @conservative_candidacy.first_name
            assert_equal 'Stanhope', @conservative_candidacy.last_name
          end
        
          should 'assign party when given' do
            assert_nil @independent_candidacy.political_party
            assert_equal @conservative_party, @conservative_candidacy.political_party
          end
        end
        
        context 'when a candidacy has an address' do
          setup do
            @dummy_response = 
            [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
              :source => 'http://anytown.gov.uk/elections/poll/foo',
              :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
              :date => '2007-05-03', 
              :electorate => '4409', 
              :ballots_issued => '1642', 
              :ballots_rejected => '31', 
              :uncontested => nil, 
              :candidacies => [{:given_name => 'Margaret', 
                                :family_name => 'Stanhope',
                                :votes => '790',
                                :elected => 'true',
                                :party => 'http://openelectiondata.org/id/parties/25',
                                :independent => nil,
                                :address => {:locality => "Barkingside",
                                             :postal_code => "IG6 1HB",
                                             :street_address => "284 Ashurst Drive",
                                             :region => "Essex"}
                                 }
              ] }]
            Poll.from_open_election_data(@dummy_response, :council => @council)
            @new_poll = Poll.last(:order => 'id')
            @new_candidacy = Candidacy.first(:order => 'id DESC', :limit => 1)
          end
          
          should_change_record_count_of :candidacy, 1, 'create'
          should_change_record_count_of :address, 1, 'create'
          
          should 'associate address with candidacy' do
            assert address = @new_candidacy.address
            assert_equal "IG6 1HB", address.postal_code
          end
        end
        
        context 'when a candidate is missing name' do
          setup do
            @dummy_response = 
            [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
              :source => 'http://anytown.gov.uk/elections/poll/foo',
              :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
              :date => '2007-05-03', 
              :electorate => '4409', 
              :ballots_issued => '1642', 
              :ballots_rejected => '31', 
              :uncontested => nil, 
              :candidacies => [{:given_name => 'Margaret', 
                                :family_name => nil,
                                :votes => '790',
                                :elected => 'true',
                                :party => 'http://openelectiondata.org/id/parties/25',
                                :independent => nil },
                               {:name => 'John Linnaeus Middleton', 
                                :votes => '342',
                                :elected => 'false',
                                :party => nil,
                                :independent => true }
                ] }]
            @old_candidacy_count = Candidacy.count
            Poll.from_open_election_data(@dummy_response, :council => @council)
            @new_poll = Poll.last(:order => 'id')
            @new_candidacy = Candidacy.first(:order => 'id DESC', :limit => 1)
          end
        
          should 'not raise exception' do
            assert_nothing_raised(Exception) { Poll.from_open_election_data(@dummy_response, :council => @council) }
          end
          
          should 'still create other candidate' do
            assert_equal @old_candidacy_count+1, Candidacy.count
            assert_equal 342, @new_candidacy.votes
          end
          
        end
      end
      
      context 'and a poll has snac_id for another council' do
        setup do
          @old_poll_count = Poll.count
          @dummy_response << { :uri => 'http://openelectiondata.org/id/polls/41UDPQ/2007-05-03', 
            :area => "http://statistics.data.gov.uk/id/local-authority-ward/#{@another_council_ward.snac_id}", 
            :date => '2007-05-03', 
            :electorate => '4409', 
            :candidacies => [{:name => 'Ian Maxwell Pardoe Pritchard', 
                              :elected => 'true',
                              :votes => '123',
                              :party => 'http://openelectiondata.org/id/parties/25' }
              ] }
        end
        
        should "not create poll if area isn't associated with council_id" do
          Poll.from_open_election_data(@dummy_response, :council => @council)
          assert_equal @old_poll_count+1, Poll.count
          assert @another_council_ward.polls.empty?
        end
        
      end
      
      context 'and a poll is uncontested' do
        setup do
          @old_poll_count, @old_candidacy_count = Poll.count, Candidacy.count
          @dummy_response << { :uri => 'http://openelectiondata.org/id/polls/41UDPQ/2007-05-03', 
            :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDPQ', 
            :date => '2007-05-03', 
            :electorate => '4409', 
            :uncontested => 'true', 
            :candidacies => [{:name => 'Ian Maxwell Pardoe Pritchard', 
                              :elected => 'true',
                              :party => 'http://openelectiondata.org/id/parties/25' }
              ] }
          Poll.from_open_election_data(@dummy_response, :council => @council)
        end
        
        should 'create polls' do
          assert_equal @old_poll_count+2, Poll.count
        end
        
        should 'mark uncontested poll as uncontested' do
          assert Poll.last(:order => 'id').uncontested
        end
        
        should 'create candidacies for poll' do
          assert_equal @old_candidacy_count+3, Candidacy.count
        end
      end
      
      context "and a matching area can't be found" do
        setup do
          @old_poll_count, @old_candidacy_count = Poll.count, Candidacy.count
          @dummy_response << { :uri => 'http://openelectiondata.org/id/polls/41UDPQ/2007-05-03', 
            :area => 'http://statistics.data.gov.uk/id/local-authority-ward/FOOBAR', 
            :date => '2007-05-03', 
            :electorate => '4409', 
            :candidacies => [{:name => 'Ian Maxwell Pardoe Pritchard', 
                              :elected => 'true',
                              :votes => '342',
                              :elected => 'false',
                              :party => 'http://openelectiondata.org/id/parties/25' }
              ] }
          Poll.from_open_election_data(@dummy_response, :council => @council)
        end
        
        should 'not create poll for area with unknown area' do
          assert_equal @old_poll_count+1, Poll.count
        end
                
        should 'create candidacies for poll' do
          assert_equal @old_candidacy_count+2, Candidacy.count
        end
      end
      
      context "and no date given" do

        should 'in general not create poll' do
          @dummy_response = 
          [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/',
            :source => 'http://anytown.gov.uk/elections/poll/foo',
            :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
            :date => nil, 
            :electorate => '4409', 
            :ballots_issued => '1642', 
            :uncontested => nil, 
            :candidacies => [{:given_name => 'Margaret', 
                              :family_name => 'Stanhope',
                              :votes => '790',
                              :elected => 'true',
                              :party => 'http://openelectiondata.org/id/parties/25',
                              :independent => nil },
                             {:name => 'John Linnaeus Middleton', 
                              :votes => '342',
                              :elected => 'false',
                              :party => nil,
                              :independent => true }
              ] }]
          assert_no_difference "Poll.count" do
            Poll.from_open_election_data(@dummy_response, :council => @council)
          end
        end
          
        context 'and date_held is in poll Resource URI' do
          setup do
            @dummy_response = 
            [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
              :source => 'http://anytown.gov.uk/elections/poll/foo',
              :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
              :date => nil, 
              :electorate => '4409', 
              :ballots_issued => '1642', 
              :uncontested => nil, 
              :candidacies => [{:given_name => 'Margaret', 
                                :family_name => 'Stanhope',
                                :votes => '790',
                                :elected => 'true',
                                :party => 'http://openelectiondata.org/id/parties/25',
                                :independent => nil },
                               {:name => 'John Linnaeus Middleton', 
                                :votes => '342',
                                :elected => 'false',
                                :party => nil,
                                :independent => true }
                ] }]
          end
          
          should 'create poll' do
            assert_difference "Poll.count", 1 do
              Poll.from_open_election_data(@dummy_response, :council => @council)
            end
          end
          
          should 'assign date_held from date in poll resource_uri' do
            poll = Poll.from_open_election_data(@dummy_response, :council => @council).first
            assert !poll.new_record? # will not have saved if invalid
            assert_equal "2007-05-03".to_date, poll.date_held
            assert_equal 'http://anytown.gov.uk/elections/poll/foo', poll.source
          end
        end
        
      end
      
      context 'and poll already exists' do
        setup do
          original_details = 
          [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
            :source => 'http://anytown.gov.uk/elections/poll/foo',
            :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
            :date => '2007-05-03', 
            :electorate => '4409', 
            # :ballots_issued => '1642', 
            :candidacies => [{:given_name => 'Margaret', 
                              :family_name => 'Stanhope',
                              :votes => nil,
                              :elected => nil,
                              :party => 'http://openelectiondata.org/id/parties/25',
                              :independent => nil },
                             {:name => 'John Linnaeus Middleton', 
                              :votes => nil,
                              :elected => nil,
                              :party => nil,
                              :independent => true }
              ] }]
          Poll.from_open_election_data(original_details, :council => @council) # create poll
          @old_poll_count, @old_candidacy_count = Poll.count, Candidacy.count
          updated_details = 
          [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
            :source => 'http://anytown.gov.uk/elections/poll/foo',
            :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
            :date => '2007-05-03', 
            :electorate => '4409', 
            :ballots_issued => '1642', 
            :candidacies => [{:given_name => 'Margaret', 
                              :family_name => 'Stanhope',
                              :votes => '790',
                              :elected => 'true',
                              :party => 'http://openelectiondata.org/id/parties/25',
                              :independent => nil },
                             {:name => 'John Linnaeus Middleton', 
                              :votes => '342',
                              :elected => 'false',
                              :party => nil,
                              :independent => true }
              ] }]          
          @poll = Poll.from_open_election_data(updated_details, :council => @council).first # update poll
        end
        
        should 'not create new poll' do
          assert_equal @old_poll_count, Poll.count
        end
        
        should 'update poll' do
          assert_equal 1642, @poll.ballots_issued
        end
        
        should 'not create candidacies' do
          assert_equal @old_candidacy_count, Candidacy.count
        end
        
        should 'update candidacies for poll' do
          candidacy = @poll.candidacies.find_by_last_name('Stanhope')
          assert_equal 790, candidacy.votes
          assert candidacy.elected?
        end
      end   
    end
  end
  
  context "A Poll instance" do
    
    should "return date_held as string as title" do
      assert_equal @poll.date_held.to_s(:event_date), @poll.title
    end
    
    should "return position, area and date_held as string as extended title" do
      assert_equal "Member for #{@poll.area.title}, #{@poll.date_held.to_s(:event_date)}", @poll.extended_title
    end
    
    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/polls/#{@poll.id}", @poll.resource_uri
    end
    
    should 'delegate area_resource_uri to area' do
      assert_equal @council.resource_uri, @poll.area_resource_uri
    end
    
    should 'delegate area_title to area' do
      assert_equal @council.title, @poll.area_title
    end
    
    context 'when returning status' do
      should 'return nil by default' do
        assert_nil Poll.new.status
      end
      
      should 'return uncontested if uncontested' do
        assert_equal 'uncontested', Poll.new(:uncontested => true).status
      end
      
    end
    
    context "when calculating turnout" do
      setup do
        @t_poll= Factory(:poll, :area => @council, :electorate => 200, :ballots_issued => 90)
      end
      
      should "return nil if electorate is nil" do
        @t_poll.electorate = nil
        assert_nil @t_poll.turnout
      end

      should "return nil if ballots issued is nil" do
        @t_poll.ballots_issued = nil
        assert_nil @t_poll.turnout
      end
      
      should "return valid ballots divided by electorate as turnout" do
        expected_result = @t_poll.ballots_issued.to_f/@t_poll.electorate.to_f
        assert_in_delta expected_result, @t_poll.turnout, 0.00000001
      end
    end
    
    context 'when returning whether rejected ballots details' do
      should 'return false if ballot_rejected nil' do
        assert !@poll.rejected_ballot_details?
      end
      
      should 'return false if ballot_rejected zero' do
        @poll.ballots_rejected = 0
        assert !@poll.rejected_ballot_details?
      end
      
      context 'and ballot_rejected non-zero' do
        setup do
          @poll.ballots_rejected = 10
        end
        
        should 'return false if all ballot rejected categories add up to zero' do
          assert !@poll.rejected_ballot_details?
        end
        
        should 'return true if all ballot rejected categories add up to greater than zero' do
          @poll.update_attributes(:ballots_missing_official_mark => 1, :ballots_void_for_uncertainty => 3)
          assert @poll.rejected_ballot_details?
          @poll.ballots_void_for_uncertainty = 0
          assert @poll.rejected_ballot_details?
        end
      end
      
    end

  end
end
