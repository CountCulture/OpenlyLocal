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
    should_belong_to :police_team
    should_validate_presence_of :council_id
    should_have_many :members
    should_have_many :committees
    should_have_many :meetings, :through => :committees
    should_have_many :datapoints
    should_have_many :polls
    should_have_many :dataset_topics, :through => :datapoints
    should_have_db_column :uid
    should_have_db_column :snac_id
    should_have_db_column :url
    should_have_db_column :police_neighbourhood_url

    should "include ScraperModel mixin" do
      assert Ward.respond_to?(:find_all_existing)
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

    context "when getting grouped datapoints" do
      setup do
        @data_grouping = Factory(:dataset_topic_grouping, :title => "demographics")
        @another_data_grouping = Factory(:dataset_topic_grouping, :title => "foo")
        @another_ward = Factory(:ward, :name => "another ward", :council => @council)

        @selected_topic_1 = Factory(:dataset_topic, :dataset_topic_grouping => @data_grouping, :title => "b title")
        @selected_topic_2 = Factory(:dataset_topic, :dataset_topic_grouping => @data_grouping, :title => "a title")
        @selected_topic_3 = Factory(:dataset_topic, :dataset_topic_grouping => @data_grouping, :title => "c title")
        @unselected_topic = Factory(:dataset_topic)
        @selected_dp_1 = Factory(:datapoint, :area => @ward, :dataset_topic => @selected_topic_1, :value => "3.99")
        @selected_dp_2 = Factory(:datapoint, :area => @ward, :dataset_topic => @selected_topic_2, :value => "4.99")
        @selected_dp_3 = Factory(:datapoint, :area => @ward, :dataset_topic => @selected_topic_3, :value => "2.99")
        @unselected_dp = Factory(:datapoint, :area => @ward, :dataset_topic => @unselected_topic)
        @wrong_ward_dp = Factory(:datapoint, :area => @another_ward, :dataset_topic => @selected_topic_1)
      end

      should "return hash of arrays" do
        assert_kind_of Hash, @ward.grouped_datapoints
        assert_kind_of Array, @ward.grouped_datapoints.values.first
      end

      should "use data groupings as keys" do
        assert @ward.grouped_datapoints.keys.include?(@data_grouping)
      end

      should "return datapoints for topics in groupings" do
        assert @ward.grouped_datapoints.values.flatten.include?(@selected_dp_1)
      end

      should "not return datapoints with topics not in groupings" do
        assert !@ward.grouped_datapoints.values.flatten.include?(@unselected_dp)
      end

      should "not return datapoints for different areas" do
        assert !@ward.grouped_datapoints.values.flatten.include?(@wrong_ward_dp)
      end
      
      should "sort by associated topic order by default" do
        assert_equal @selected_dp_2, @ward.grouped_datapoints[@data_grouping].first
      end

      should "return sorted if data_grouping has sort_by set" do
        @data_grouping.update_attribute(:sort_by, "value")
        assert_equal @selected_dp_3, @ward.grouped_datapoints[@data_grouping].first
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
        assert_equal [@ward_dp, @another_ward_dp], dps
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
