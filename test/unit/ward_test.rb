require File.expand_path('../../test_helper', __FILE__)

class WardTest < ActiveSupport::TestCase
  subject { @ward }
  context "The Ward class" do
    setup do
      @ward = Factory(:ward)
    end

    should validate_presence_of :name
    # should validate_uniqueness_of(:name).scoped_to [:council_id, :defunkt] #note doesn't seem to take any notice of defunkt_scope so tested properly below
    # should validate_uniqueness_of :snac_id#, :allow_nil => true
    should belong_to :council
    should belong_to :police_team
    should validate_presence_of :council_id
    should have_many :members
    should have_many :committees
    should have_many(:meetings).through :committees
    should have_many :datapoints
    should have_many :polls
    should have_many(:dataset_topics).through :datapoints
    should have_one  :boundary
    # should belong_to :crime_area
    [:uid, :snac_id, :url, :police_neighbourhood_url, :crime_area_id].each do |column|
      should have_db_column column
    end

    should "include ScraperModel mixin" do
      assert Ward.respond_to?(:find_all_existing)
    end
    
    should "include AreaMethods mixin" do
      assert Ward.new.respond_to?(:grouped_datapoints)
    end
    
    should 'not belong to defunkt police team' do
      police_team = Factory(:police_team)
      @ward.update_attribute(:police_team, police_team)
      assert_equal police_team, @ward.police_team
      police_team.update_attribute(:defunkt, true)
      assert_nil @ward.police_team(true)
    end
    
    context 'when validating uniqueness of name' do
      setup do
        @council_1 = Factory(:council, :name => "Council 1")
        @council_2 = Factory(:council, :name => "Council 2")
        @ward_1 = Factory(:ward, :name => 'foo1', :council => @council_2)
        @ward_2 = Factory.build(:ward, :name => 'foo1', :council => @council_2)
      end
      
      should 'allow same name for wards with different councils' do
        @ward_1.update_attribute(:council, @council_1)
        assert @ward_2.valid?
      end
      
      should 'not allow same name for wards with same council' do
        assert !@ward_2.valid?
      end
      
      should 'allow same name for wards with same council if both are defunkt and snac ids are different' do
        @ward_1.update_attributes(:defunkt => true, :snac_id => '00ABCD')
        @ward_2.defunkt = true
        @ward_2.snac_id = '00ABCX'
        assert @ward_2.valid?
      end
      
      should 'allow same name for wards with same council if existing one is defunkt and snac ids are different' do
        @ward_1.update_attributes(:defunkt => true, :snac_id => '00ABCD')
        @ward_2.snac_id = '00ABCX'
        assert @ward_2.valid?
      end
      
      should 'allow same name for wards with same council if new one is defunkt, old one is not and snac ids are different' do
        @ward_1.update_attributes(:snac_id => '00ABCD')
        @ward_2.snac_id = '00ABCX'
        @ward_2.defunkt = true
        assert @ward_2.valid?
      end
      
      should 'not allow same name for wards with same council if neither are defunkt and snac ids are different' do
        @ward_1.update_attribute(:snac_id, '00ABCD')
        @ward_2.snac_id = '00ABCX'
        assert !@ward_2.valid?
      end
      
      should 'not allow same name for wards with same council if both are defunkt and snac id is same' do
        @ward_1.update_attributes(:defunkt => true, :snac_id => '00ABCD')
        @ward_2.defunkt = true
        @ward_2.snac_id = '00ABCD'
        assert !@ward_2.valid?
      end
      
      should 'not allow same name for wards with same council if one is missing snac_id' do
        @ward_1.update_attribute(:defunkt, true)
        @ward_2.snac_id = '00ABCD'
        assert !@ward_2.valid?
      end
      
      should 'not allow same name for wards with same council if one has blank snac_id' do
        @ward_1.update_attributes(:defunkt => true, :snac_id => '')
        @ward_2.snac_id = '00ABCD'
        assert !@ward_2.valid?
      end
    end
    
    context 'when validating uniqueness of snac id' do
      should 'not allow same snac id even with different councils' do
        @ward.update_attribute(:snac_id, '00ABCD')
        another_ward = Factory.build(:ward, :name => 'Another ward', :council => Factory(:another_council), :snac_id => '00ABCD')
        assert !another_ward.valid?
        assert another_ward.errors[:snac_id]
      end
      
      should 'allow several wards with nil snac id' do
        another_ward = Factory.build(:ward, :name => 'Another ward', :council => Factory(:another_council)) # snac_id => nil
        assert another_ward.valid?
      end
      
      should 'allow several wards with blank snac id' do
        @ward.update_attribute(:snac_id, '')
        another_ward = Factory.build(:ward, :name => 'Another ward', :council => Factory(:another_council), :snac_id => '') # snac_id => nil
        assert another_ward.valid?
      end
    end
    
    context 'should have defunkt named scope which' do
      setup do
        @council = @ward.council
        @defunkt_ward = Factory(:defunkt_ward, :council => @council)
        @another_council = Factory(:another_council)
        @another_ward = Factory(:ward, :name => 'another ward', :council => @another_council)
        @another_defunkt_ward = Factory(:defunkt_ward, :name => 'another defunkt ward', :council => @another_council)
      end
      
      should 'return defunkt wards only' do
        defunkt_wards = Ward.defunkt
        assert defunkt_wards.include?(@defunkt_ward)
        assert defunkt_wards.include?(@another_defunkt_ward)
        assert !defunkt_wards.include?(@ward)
      end
      
    end
    
    context 'should have current named scope and' do
      setup do
        @council = @ward.council
        @defunkt_ward = Factory(:defunkt_ward, :council => @council)
        @another_council = Factory(:another_council)
        @another_ward = Factory(:ward, :name => 'another ward', :council => @another_council)
        @another_defunkt_ward = Factory(:defunkt_ward, :name => 'another defunkt ward', :council => @another_council)
        @current_wards = Ward.current
      end
      
      should 'return current wards only' do
        assert @current_wards.include?(@ward)
        assert @current_wards.include?(@another_ward)
        assert !@current_wards.include?(@defunkt_ward)
      end
      
    end

    context 'when finding from resource_uri' do
      setup do
        @snac_id_ward = Factory(:ward, :name => 'Snac_id ward', :snac_id => '41UDGE', :council => @ward.council)
      end
      
      should 'return ward with snac_id identified in stats.data.gov.uk URI' do
        assert_equal @snac_id_ward, Ward.find_from_resource_uri('http://statistics.data.gov.uk/id/local-authority-ward/41UDGE')
      end
      
      should 'return nil if no matching ward' do
        assert_nil Ward.find_from_resource_uri('http://statistics.data.gov.uk/id/local-authority-ward/41UDXX')
      end
      
      should 'return ward with id identified in openlylocal URI' do
        assert_equal @ward, Ward.find_from_resource_uri("http://openlylocal.com/id/wards/#{@ward.id}")
      end
    end

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
      assert_equal "Forward", Ward.new(:name => "Forward ward").name
      assert_equal "Forward", Ward.new(:name => "Forward").name
    end
    
    context 'when returning fix_my_street_url' do
      should 'build url using snac id' do
        @ward.snac_id = '00ABCD'
        assert_equal 'http://fixmystreet.com/reports/00ABCD', @ward.fix_my_street_url
      end
      
      should 'return nil if snac_id blank' do
        assert_nil @ward.fix_my_street_url
        @ward.snac_id = ''
        assert_nil @ward.fix_my_street_url
      end
      
    end

    context "when matching existing member against params should override default and" do
      should "should match uid" do
        assert !@ward.matches_params(:uid => 42)
        @ward.uid = 42
        assert !@ward.matches_params(:uid => nil)
        assert !@ward.matches_params(:uid => 41)
        assert !@ward.matches_params
        assert @ward.matches_params(:uid => 42)
      end

      should "should match given name" do
        assert !@ward.matches_params(:name => "foo")
        assert @ward.matches_params(:name => @ward.name)
      end

      should "should match name in preference to uid" do
        assert @ward.matches_params(:uid => 99, :name => @ward.name)
      end

      should "should not match when no params" do
        assert !@ward.matches_params
      end

      should "should clean up ward name when matching" do
        assert @ward.matches_params(:name => " #{@ward.name} Ward ")
      end

      should "have sibling wards" do
        @sibling_ward = Factory(:ward, :name => 'sibling ward', :council => @council)
        @unrelated_ward = Factory(:ward, :name => 'unrelated ward', :council => Factory(:another_council))
        assert_equal [@sibling_ward], @ward.siblings
      end
    end
    
    context "when returning related" do
      should "return all wards in council area" do
        @sibling_ward = Factory(:ward, :name => 'Sibling ward', :council => @council)
        @unrelated_ward = Factory(:ward, :name => 'Unrelated ward', :council => Factory(:another_council))
        assert_equal [@ward, @sibling_ward], @ward.related
      end
      
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

    context "when getting datapoints for topics" do
      setup do
        @another_ward = Factory(:ward, :name => "Another ward", :council => @ward.council)
        @ward_dp = Factory(:datapoint, :area => @ward)
        @another_ward_dp = Factory(:datapoint, :area => @ward)
        @wrong_ward_dp = Factory(:datapoint, :area => @another_ward)
        @ward.update_attribute(:ness_id, 1234)
      end

      should "return datapoints for ward with given topic ids" do
        dps = @ward.datapoints_for_topics([@ward_dp.dataset_topic.id, @another_ward_dp.dataset_topic.id])
        assert_equal [@ward_dp, @another_ward_dp], dps.sort_by(&:created_at)
      end

      should "return empty array if no given topic ids" do
        assert_equal [], @ward.datapoints_for_topics([])
        assert_equal [], @ward.datapoints_for_topics()
      end

      should "return empty array if no ness_id" do
        @ward.update_attribute(:ness_id, nil)
        assert_equal [], @ward.datapoints_for_topics([@ward_dp.dataset_topic.id])
      end

      context "and datapoints don't exist" do
        setup do
          @ons_topic_1 = Factory(:dataset_topic, :ons_uid => 63)
          @ons_topic_2 = Factory(:dataset_topic, :ons_uid => 2329)
          NessUtilities::RawClient.any_instance.stubs(:_http_post).returns(dummy_xml_response(:ness_datapoints))
        end

        should "request info from Ness for topics for ward" do
          NessUtilities::RawClient.expects(:new).with('Tables', [['Areas', @ward.ness_id], ['Variables',[@ons_topic_1.ons_uid,@ons_topic_2.ons_uid]]]).returns(stub(:process_and_extract_datapoints=>[]))
          @ward.datapoints_for_topics([@ons_topic_1.id, @ons_topic_2.id])
        end

        should "save results of Ness query as datapoints" do
          assert_difference('Datapoint.count', 2) do
            @ward.datapoints_for_topics([@ons_topic_1.id,@ons_topic_2.id])
          end
        end

        should "return newly saved datapoints" do
          dps = @ward.datapoints_for_topics([@ons_topic_1.id,@ons_topic_2.id])
          assert_equal 2, dps.size
          assert_kind_of Datapoint, dps.first
        end

        should "store data returned from Ness query in datapoints" do
          dps = @ward.datapoints_for_topics([@ons_topic_1.id,@ons_topic_2.id])
          dp1 = dps.detect{ |dp| dp.dataset_topic_id == @ons_topic_1.id}
          dp2 = dps.detect{ |dp| dp.dataset_topic_id == @ons_topic_2.id}
          assert_equal @ward, dp1.area
          assert_equal 37.9, dp1[:value] # we're just checking stored value, not value after it's been typecast
          assert_equal @ward, dp2.area
          assert_equal 9709.0, dp2[:value]
        end
      end

    end
  end
end
