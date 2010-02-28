require 'test_helper'

class DatapointTest < ActiveSupport::TestCase
  subject { @datapoint }
  context "The Datapoint class" do
    setup do
      @datapoint = Factory(:datapoint)
    end

    should_validate_presence_of :value
    should_validate_presence_of :dataset_topic_id
    should_validate_presence_of :area_id
    should_validate_presence_of :area_type
    should_belong_to :dataset_topic
    should_belong_to :area
    should "belong_to dataset_family through dataset_topic" do
      assert_equal @datapoint.dataset_topic.dataset_family, @datapoint.dataset_family
    end
    
    should "alias dataset_topic as subject" do
      assert_equal @datapoint.dataset_topic, @datapoint.subject
    end
    
    should "restrict to given ness topic ids" do
      @ward = @datapoint.area
      datapoint_1 = Factory(:datapoint, :area => @ward)
      datapoint_2 = Factory(:datapoint, :area => @ward)
      datapoint_3 = Factory(:datapoint, :area => @ward)
      topic_uids = [ datapoint_2.dataset_topic.ons_uid,
                     datapoint_3.dataset_topic.ons_uid]
      assert_equal [datapoint_2, datapoint_3], Datapoint.with_topic_uids(topic_uids)
    end
    
    context "when limiting to those whose topics are in a topic_grouping" do
      setup do
        @ward = @datapoint.area
        @datapoint_1 = Factory(:datapoint, :area => @ward)
        @datapoint_2 = Factory(:datapoint, :area => @ward)
        @datapoint_3 = Factory(:datapoint, :area => @ward)
        
        @grouping = Factory(:dataset_topic_grouping)
        @another_grouping = Factory(:dataset_topic_grouping)
        @grouping.dataset_topics << [@datapoint.dataset_topic, @datapoint_2.dataset_topic]
        @another_grouping.dataset_topics << [@datapoint_3.dataset_topic]
      end
      
      should "return only those datapoints with topics in topic grouping" do
        assert_equal [@datapoint, @datapoint_2, @datapoint_3], Datapoint.with_topic_grouping
      end

    end
    
    context "when limiting to those whose topics are in a dataset" do
      setup do
        @ward = @datapoint.area
        @datapoint_1 = Factory(:datapoint, :area => @ward)
        @dataset_topic_1 = @datapoint_1.dataset_topic
        @dataset_family_1 = @dataset_topic_1.dataset_family
        @dataset = @dataset_family_1.dataset
        @dataset_family_2 = Factory(:dataset_family, :dataset => @dataset)
        @dataset_topic_2 = Factory(:dataset_topic, :dataset_family => @dataset_family_2)

        @datapoint_2 = Factory(:datapoint, :area => @ward) #different topic, family, dataset
        @datapoint_3 = Factory(:datapoint, :area => @ward, :dataset_topic => @dataset_topic_2)
        
        # @grouping = Factory(:dataset_topic_grouping)
        # @another_grouping = Factory(:dataset_topic_grouping)
        # @grouping.dataset_topics << [@datapoint.dataset_topic, @datapoint_2.dataset_topic]
        # @another_grouping.dataset_topics << [@datapoint_3.dataset_topic]
      end
      
      should "return only those datapoints with dataset_families in given dataset" do
        assert_equal [@datapoint_1, @datapoint_3], Datapoint.in_dataset(@dataset)
      end

    end

    context "when limiting to given restrictions" do
      should_eventually "return empty array if no restrictions" do
        assert_equal [], Datapoint.limited_to
      end
    end
  end

  context "an Datapoint instance" do
    setup do
      @dataset_topic = Factory(:dataset_topic, :muid => 1)
      @datapoint = Factory(:datapoint, :dataset_topic => @dataset_topic)
      @ward = @datapoint.area
    end

    should "include topic id in title" do
      assert_equal "#{@dataset_topic.title}", @datapoint.title
    end

    should "include ward and topic in extended title" do
      assert_equal "#{@dataset_topic.title} (#{@ward.name})", @datapoint.extended_title
    end

    should "delegate muid_format to dataset_topic" do
      @dataset_topic.stubs(:muid_format).returns('%1f')
      assert_equal '%1f', @datapoint.muid_format
    end

    should "delegate muid_type to dataset_topic" do
      @dataset_topic.stubs(:muid_type).returns('foo')
      assert_equal 'foo', @datapoint.muid_type
    end

    should "delegate ons_uid to dataset_topic" do
      @dataset_topic.stubs(:ons_uid).returns(456)
      assert_equal 456, @datapoint.ons_uid
    end

    should "delegate short_title to dataset_topic" do
      @dataset_topic.stubs(:short_title).returns('short titl')
      assert_equal 'short titl', @datapoint.short_title
    end
    
    should "return statistical dataset, family and topic as parents" do
      expected_parents = [@datapoint.dataset_topic.dataset_family.dataset, @datapoint.dataset_topic.dataset_family, @datapoint.dataset_topic]
      assert_equal expected_parents, @datapoint.parents
    end
    
    context "when returning value" do
      # Muids = { 1 => ['Count'],
      #           2 => ['Percentage', "%.1f%"],
      #           9 => ['Pounds Sterling', "£%d"],
      #           14 => ['Years', "%.1f"]}

      should "return as integer by default" do
        @dataset_topic.update_attribute(:muid, nil)
        assert_kind_of Integer, @datapoint.reload.value # reload to get 'cast' value, not value it was given on instantiation
      end
      
      should "return as integer when muid is Count" do
        assert_kind_of Integer, @datapoint.reload.value
      end
      
      should "return as correct integer without losing precision when value is very large" do
        @datapoint.update_attribute(:value, 1234567890123)
        assert_equal 1234567890123, @datapoint.reload.value
      end
      
      should "return as float when muid is Percentage" do
        @dataset_topic.update_attribute(:muid, 2)
        assert_kind_of Float, @datapoint.reload.value
      end
      
      should "return as float when muid is Years" do
        @dataset_topic.update_attribute(:muid, 14)
        assert_kind_of Float, @datapoint.reload.value
      end
      
      should "return 1 as Yes when muid is Yes/No" do
        @dataset_topic.update_attribute(:muid, 100)
        @datapoint.update_attribute(:value, 1)
        assert_equal "Yes", @datapoint.reload.value
      end
      
      should "return 0 as No when muid is Yes/No" do
        @dataset_topic.update_attribute(:muid, 100)
        @datapoint.update_attribute(:value, 0)
        assert_equal "No", @datapoint.reload.value
      end
    end

    context "when returning related datapoints" do
      context "and area is a ward" do
        setup do
          @sibling_ward = Factory(:ward, :name => 'A sibling ward', :council => @ward.council)
          @unrelated_ward = Factory(:ward, :name => 'Unrelated ward', :council => Factory(:another_council))
          @same_topic_sibling_ward_dp = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @sibling_ward)
          @same_topic_unrelated_ward_dp = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @unrelated_ward)
          @different_topic_and_sibling_ward_dp = Factory(:datapoint, :area => @sibling_ward)
        end

        should "include datapoints for same topic from sibling wards" do
          assert @datapoint.related_datapoints.include?(@same_topic_sibling_ward_dp)
        end

        should "include original datapoint" do
          assert @datapoint.related_datapoints.include?(@datapoint)
        end

        should "not include datapoints for same topic from other wards" do
          assert !@datapoint.related_datapoints.include?(@same_topic_unrelated_ward_dp)
        end

        should "not include datapoints for same ward from other topics" do
          assert !@datapoint.related_datapoints.include?(@different_topic_and_sibling_ward_dp)
        end

        should "return datapoints in alphabetical order on wards" do
          assert_equal @same_topic_sibling_ward_dp, @datapoint.related_datapoints.first
        end
      end

      context "and area is a council" do
        setup do
          @council = @ward.council
          @council.update_attribute(:authority_type, "District")
          @datapoint.area = @council
          @datapoint.save!
          @sibling_council = Factory(:council, :name => 'Sibling council', :authority_type => "District")
          @unrelated_council = Factory(:council, :name => 'Unrelated council', :authority_type => "County")
          @same_topic_sibling_council_dp = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @sibling_council)
          @same_topic_unrelated_council_dp = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @unrelated_council)
          @different_topic_and_sibling_council_dp = Factory(:datapoint, :area => @sibling_council)
        end

        should "include datapoints for same topic from sibling wards" do
          assert @datapoint.related_datapoints.include?(@same_topic_sibling_council_dp)
        end

        should "include original datapoint" do
          assert @datapoint.related_datapoints.include?(@datapoint)
        end

        should "not include datapoints for same topic from other wards" do
          assert !@datapoint.related_datapoints.include?(@same_topic_unrelated_council_dp)
        end

        should "not include datapoints for same ward from other topics" do
          assert !@datapoint.related_datapoints.include?(@different_topic_and_sibling_council_dp)
        end

        should "return datapoints in alphabetical order on councils" do
          assert_equal @datapoint, @datapoint.related_datapoints.first
        end
      end
    end
  end
end
