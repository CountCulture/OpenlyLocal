require 'test_helper'

class OnsDatasetTopicTest < ActiveSupport::TestCase
  subject { @ons_dataset_topic }
  context "The OnsDatasetTopic class" do
    setup do
      @ons_dataset_topic = Factory(:ons_dataset_topic)
    end
    should_validate_presence_of :title
    # should_validate_presence_of :ons_uid
    should_validate_presence_of :ons_dataset_family_id
    should_belong_to :ons_dataset_family
    should_belong_to :dataset_topic_grouping
    should_have_many :ons_datapoints
    should_have_db_column :muid, :description, :data_date, :short_title
    
  end

  context "An OnsDatasetTopic instance" do
    setup do
      @ons_dataset_topic = Factory(:ons_dataset_topic)
    end

    context "when returning extended_title" do
      should "return title attribute including muid type if set" do
        topic = OnsDatasetTopic.new(:title => 'foo')
        topic.stubs(:muid_type => "Percentage")
        assert_equal 'foo (Percentage)', topic.extended_title
      end
      
      should "return title attribute by default" do
        assert_equal 'foo', OnsDatasetTopic.new(:title => 'foo').title
      end
    end

    context "when returning short_title" do
      should "return title attribute if :short_title attribute is blank" do
        assert_equal 'foo', OnsDatasetTopic.new(:title => 'foo').short_title
      end

      should "return short_title attribute if set" do
        assert_equal 'bar', OnsDatasetTopic.new(:title => 'foo', :short_title => 'bar').short_title
      end
    end

    context "when returning muid_format" do
      should "return nil if muid is blank" do
        assert_nil Factory.build(:ons_dataset_topic).muid_format
        assert_nil Factory.build(:ons_dataset_topic, :muid => 99).muid_format
      end

      should "return format when set" do
        assert_equal "%.1f%", Factory.build(:ons_dataset_topic, :muid => 2).muid_format
      end
    end

    context "when returning muid_type" do
      should "return nil if muid is blank" do
        assert_nil Factory.build(:ons_dataset_topic).muid_type
        assert_nil Factory.build(:ons_dataset_topic, :muid => 99).muid_type
      end

      should "return type when set" do
        assert_equal "Percentage", Factory.build(:ons_dataset_topic, :muid => 2).muid_type
      end
    end

    should "return statistical dataset and family as parents" do
      expected_parents = [@ons_dataset_topic.ons_dataset_family.statistical_dataset, @ons_dataset_topic.ons_dataset_family]
      assert_equal expected_parents, @ons_dataset_topic.parents
    end

    context "when updating datapoints for council" do
      setup do
        @council = Factory(:council)
        @council.update_attribute(:ness_id, 42)
        @ward1 = Factory(:ward, :name => 'ward1', :ness_id => 211, :council => @council)
        @ward2 = Factory(:ward, :name => 'ward2', :ness_id => 215, :council => @council)
        dummy_response = [ { :ness_area_id => '215', :value => '42', :ness_topic_id => '123'},
                           { :ness_area_id => '211', :value => '51', :ness_topic_id => '123'}]
        NessUtilities::RawClient.stubs(:new).returns(stub(:process_and_extract_datapoints => dummy_response))
      end

      should "should fetch data from Ness database" do
        NessUtilities::RawClient.expects(:new).with('ChildAreaTables', [['ParentAreaId', @council.ness_id], ['LevelTypeId', '14'], ['Variables', @ons_dataset_topic.ons_uid]]).returns(stub(:process_and_extract_datapoints=>[]))
        @ons_dataset_topic.update_datapoints(@council)
      end

      should "not fetch data from Ness database when council has no ness_id" do
        @council.update_attribute(:ness_id, nil)
        NessUtilities::RawClient.expects(:new).never
        @ons_dataset_topic.update_datapoints(@council)
      end

      should "save datapoints" do
        assert_difference 'OnsDatapoint.count', 2 do
          @ons_dataset_topic.update_datapoints(@council)
        end
      end

      should "associate datapoints with correct wards" do
        @ons_dataset_topic.update_datapoints(@council)
        assert_equal 51.0, @ward1.ons_datapoints.first[:value]
        assert_equal 42.0, @ward2.ons_datapoints.first[:value]
      end

      should "return datapoints" do
        assert_kind_of Array, dps = @ons_dataset_topic.update_datapoints(@council)
        assert_equal 2, dps.size
        assert_kind_of OnsDatapoint, dps.first
      end

      should "update existing datapoints" do
        @existing_datapoint = @ward2.ons_datapoints.create(:ons_dataset_topic_id => @ons_dataset_topic.id, :value => '99')
        assert_difference 'OnsDatapoint.count', 1 do
          @ons_dataset_topic.update_datapoints(@council)
        end
        assert_equal 42.0, @existing_datapoint.reload[:value]
      end

      context "and empty values returned by Ness client" do
        setup do
          dummy_bad_response = [ { :ness_area_id => '215', :value => '', :ness_topic_id => '123'},
                             { :ness_area_id => '211', :value => nil, :ness_topic_id => '123'}]
          NessUtilities::RawClient.expects(:new).returns(stub(:process_and_extract_datapoints => dummy_bad_response)) # expects overrides stubbing
        end

        should "not add datapoints" do
          assert_no_difference 'OnsDatapoint.count' do
            @ons_dataset_topic.update_datapoints(@council)
          end
        end
      end

      context "and datapoint ness_id can't be matched by ward (e.g. ward might not have ness_id)" do
        setup do
          @ward1.update_attribute(:ness_id, 999)
        end

        should "not raise exception" do
          assert_nothing_raised(Exception) { @ons_dataset_topic.update_datapoints(@council) }
        end

        should "add matched datapoint" do
          @ons_dataset_topic.update_datapoints(@council)
          assert @ward1.ons_datapoints.empty?
          assert_equal 42.0, @ward2.ons_datapoints.first[:value]
        end

        should "not add unmatched datapoint" do
          assert_difference 'OnsDatapoint.count', 1 do
            @ons_dataset_topic.update_datapoints(@council)
          end
        end

        should "update matching datapoint" do
          @existing_datapoint = @ward2.ons_datapoints.create(:ons_dataset_topic_id => @ons_dataset_topic.id, :value => '99')
          @ons_dataset_topic.update_datapoints(@council)
          assert_equal 42.0, @existing_datapoint.reload[:value]
        end
      end

    end

    context "when processing" do
      setup do
        @council = Factory(:council, :ness_id => 211)
        @another_council = Factory(:another_council, :ness_id => 242)
        @no_ness_council = Factory(:tricky_council)
        @ons_dataset_topic.stubs(:update_datapoints)
      end

      should "update datapoints for councils with ness_id" do
        @ons_dataset_topic.expects(:update_datapoints).twice.with(){|council| [@council.id, @another_council.id].include?(council.id)}
        @ons_dataset_topic.process
      end

      should "not update datapoints for councils without ness_id" do
        @ons_dataset_topic.expects(:update_datapoints).with(){|council| @no_ness_council.id == council.id }.never
        @ons_dataset_topic.process
      end
    end
    
    context "when running perform method" do
      setup do
        @council = Factory(:council, :ness_id => 211)
        @another_council = Factory(:another_council, :ness_id => 242)
        @no_ness_council = Factory(:tricky_council)
        @ons_dataset_topic.stubs(:update_datapoints)
      end

      should "process topic" do
        @ons_dataset_topic.expects(:process)
        @ons_dataset_topic.perform
      end

      should "email results" do
        @ons_dataset_topic.perform
        assert_sent_email do |email|
          email.subject =~ /ONS Dataset Topic updated/ && email.body =~ /#{@ons_dataset_topic.title}/m
        end
      end
    end
  end
end
