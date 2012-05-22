require File.expand_path('../../test_helper', __FILE__)

class DatasetTopicTest < ActiveSupport::TestCase
  subject { @dataset_topic }
  context "The DatasetTopic class" do
    setup do
      @dataset_topic = Factory(:dataset_topic)
    end
    should_validate_presence_of :title
    # should_validate_presence_of :ons_uid
    should_validate_presence_of :dataset_family_id
    should belong_to :dataset_family
    should belong_to :dataset_topic_grouping
    should have_many :datapoints
    should_have_db_column :muid, :description, :data_date, :short_title
    
  end

  context "An DatasetTopic instance" do
    setup do
      @dataset_topic = Factory(:dataset_topic)
    end

    context "when returning extended_title" do
      should "return title attribute including muid type if set" do
        topic = DatasetTopic.new(:title => 'foo')
        topic.stubs(:muid_type => "Percentage")
        assert_equal 'foo (Percentage)', topic.extended_title
      end
      
      should "return title attribute by default" do
        assert_equal 'foo', DatasetTopic.new(:title => 'foo').title
      end
    end

    context "when returning short_title" do
      should "return title attribute if :short_title attribute is blank" do
        assert_equal 'foo', DatasetTopic.new(:title => 'foo').short_title
      end

      should "return short_title attribute if set" do
        assert_equal 'bar', DatasetTopic.new(:title => 'foo', :short_title => 'bar').short_title
      end
    end

    context "when returning muid_format" do
      should "return nil if muid is blank" do
        assert_nil Factory.build(:dataset_topic).muid_format
        assert_nil Factory.build(:dataset_topic, :muid => 99).muid_format
      end

      should "return format when set" do
        assert_equal "%.1f%", Factory.build(:dataset_topic, :muid => 2).muid_format
      end
    end

    context "when returning muid_type" do
      should "return nil if muid is blank" do
        assert_nil Factory.build(:dataset_topic).muid_type
        assert_nil Factory.build(:dataset_topic, :muid => 99).muid_type
      end

      should "return type when set" do
        assert_equal "Percentage", Factory.build(:dataset_topic, :muid => 2).muid_type
      end
    end

    should "return statistical dataset and family as parents" do
      expected_parents = [@dataset_topic.dataset_family.dataset, @dataset_topic.dataset_family]
      assert_equal expected_parents, @dataset_topic.parents
    end
    
    context "when updating council datapoints" do
      setup do
        @council_1 = Factory(:council, :ness_id => 12)
        @council_2 = Factory(:council, :name => "Council 2", :ness_id => 35)
        dummy_response = [ { :ness_area_id => '35', :value => '42', :ness_topic_id => '123'},
                           { :ness_area_id => '12', :value => '51', :ness_topic_id => '123'}]
        NessUtilities::RestClient.stubs(:new).returns(stub(:response => dummy_response))
      end

      should "should fetch data from Ness database" do
        NessUtilities::RestClient.expects(:new).with(:get_tables, :areas => ['12','35'], :variables => @dataset_topic.ons_uid).returns(stub(:response=>[]))
        @dataset_topic.update_council_datapoints
      end

      should "save datapoints" do
        assert_difference 'Datapoint.count', 2 do
          @dataset_topic.update_council_datapoints
        end
      end

      should "associate datapoints with correct councils" do
        @dataset_topic.update_council_datapoints
        assert_equal 51.0, @council_1.datapoints.first[:value]
        assert_equal 42.0, @council_2.datapoints.first[:value]
      end

      should "return datapoints" do
        assert_kind_of Array, dps = @dataset_topic.update_council_datapoints
        assert_equal 2, dps.size
        assert_kind_of Datapoint, dps.first
      end

      should "update existing datapoints" do
        @existing_datapoint = @council_2.datapoints.create(:dataset_topic_id => @dataset_topic.id, :value => '99')
        assert_difference 'Datapoint.count', 1 do
          @dataset_topic.update_council_datapoints
        end
        assert_equal 42.0, @existing_datapoint.reload[:value]
      end

      context "and empty values returned by Ness client" do
        setup do
          dummy_bad_response = [ { :ness_area_id => '215', :value => '', :ness_topic_id => '123'},
                             { :ness_area_id => '211', :value => nil, :ness_topic_id => '123'}]
          NessUtilities::RestClient.expects(:new).returns(stub(:response => dummy_bad_response)) # expects overrides stubbing
        end

        should "not add datapoints" do
          assert_no_difference 'Datapoint.count' do
            @dataset_topic.update_council_datapoints
          end
        end
      end

      context "and datapoint ness_id can't be matched to council (e.g. might be for defunkt council)" do
        setup do
          @council_1.update_attribute(:ness_id, 999)
        end

        should "not raise exception" do
          assert_nothing_raised(Exception) { @dataset_topic.update_council_datapoints }
        end
        
        should "still add datapoint for council that does match raise exception" do
          assert_difference 'Datapoint.count', 1 do
            @dataset_topic.update_council_datapoints
          end
          assert_equal 42.0, @council_2.datapoints.first[:value]
        end
      end

    end
    
    context "when updating ward datapoints for given council" do
      setup do
        @council = Factory(:council)
        @council.update_attribute(:ness_id, 42)
        @ward1 = Factory(:ward, :name => 'ward1', :ness_id => 211, :council => @council)
        @ward2 = Factory(:ward, :name => 'ward2', :ness_id => 215, :council => @council)
        dummy_response = [ { :ness_area_id => '215', :value => '42', :ness_topic_id => '123'},
                           { :ness_area_id => '211', :value => '51', :ness_topic_id => '123'}]
        NessUtilities::RestClient.stubs(:new).returns(stub(:response => dummy_response))
      end

      should "should fetch data from Ness database" do
        NessUtilities::RestClient.expects(:new).with(:get_child_area_tables, :parent_area_id => @council.ness_id, :level_type_id => 14, :variables =>  @dataset_topic.ons_uid).returns(stub(:response => []))
        @dataset_topic.update_ward_datapoints(@council)
      end

      should "not fetch data from Ness database when council has no ness_id" do
        @council.update_attribute(:ness_id, nil)
        NessUtilities::RawClient.expects(:new).never
        @dataset_topic.update_ward_datapoints(@council)
      end

      should "save datapoints" do
        assert_difference 'Datapoint.count', 2 do
          @dataset_topic.update_ward_datapoints(@council)
        end
      end

      should "associate datapoints with correct wards" do
        @dataset_topic.update_ward_datapoints(@council)
        assert_equal 51.0, @ward1.datapoints.first[:value]
        assert_equal 42.0, @ward2.datapoints.first[:value]
      end

      should "return datapoints" do
        assert_kind_of Array, dps = @dataset_topic.update_ward_datapoints(@council)
        assert_equal 2, dps.size
        assert_kind_of Datapoint, dps.first
      end

      should "update existing datapoints" do
        @existing_datapoint = @ward2.datapoints.create(:dataset_topic_id => @dataset_topic.id, :value => '99')
        assert_difference 'Datapoint.count', 1 do
          @dataset_topic.update_ward_datapoints(@council)
        end
        assert_equal 42.0, @existing_datapoint.reload[:value]
      end

      context "and empty values returned by Ness client" do
        setup do
          dummy_bad_response = [ { :ness_area_id => '215', :value => '', :ness_topic_id => '123'},
                             { :ness_area_id => '211', :value => nil, :ness_topic_id => '123'}]
          NessUtilities::RestClient.expects(:new).returns(stub(:response => dummy_bad_response)) # expects overrides stubbing
        end

        should "not add datapoints" do
          assert_no_difference 'Datapoint.count' do
            @dataset_topic.update_ward_datapoints(@council)
          end
        end
      end

      context "and datapoint ness_id can't be matched by ward (e.g. ward might not have ness_id)" do
        setup do
          @ward1.update_attribute(:ness_id, 999)
        end

        should "not raise exception" do
          assert_nothing_raised(Exception) { @dataset_topic.update_ward_datapoints(@council) }
        end

        should "add matched datapoint" do
          @dataset_topic.update_ward_datapoints(@council)
          assert @ward1.datapoints.empty?
          assert_equal 42.0, @ward2.datapoints.first[:value]
        end

        should "not add unmatched datapoint" do
          assert_difference 'Datapoint.count', 1 do
            @dataset_topic.update_ward_datapoints(@council)
          end
        end

        should "update matching datapoint" do
          @existing_datapoint = @ward2.datapoints.create(:dataset_topic_id => @dataset_topic.id, :value => '99')
          @dataset_topic.update_ward_datapoints(@council)
          assert_equal 42.0, @existing_datapoint.reload[:value]
        end
      end

    end

    context "when processing" do
      setup do
        @council = Factory(:council, :ness_id => 211)
        @another_council = Factory(:another_council, :ness_id => 242)
        @no_ness_council = Factory(:tricky_council)
        @dataset_topic.stubs(:update_ward_datapoints)
      end
      
      should "update council datapoints" do
        @dataset_topic.expects(:update_council_datapoints)
        @dataset_topic.process
      end
      
      should "update ward datapoints for councils with ness_id" do
        @dataset_topic.expects(:update_ward_datapoints).twice.with(){|council| [@council.id, @another_council.id].include?(council.id)}
        @dataset_topic.process
      end

      should "not update ward datapoints for councils without ness_id" do
        @dataset_topic.expects(:update_ward_datapoints).with(){|council| @no_ness_council.id == council.id }.never
        @dataset_topic.process
      end
    end
    
    context "when running perform method" do
      setup do
        @council = Factory(:council, :ness_id => 211)
        @another_council = Factory(:another_council, :ness_id => 242)
        @no_ness_council = Factory(:tricky_council)
        @dataset_topic.stubs(:update_ward_datapoints)
      end

      should "process topic" do
        @dataset_topic.expects(:process)
        @dataset_topic.perform
      end

      should "email results" do
        @dataset_topic.perform
        assert_sent_email do |email|
          email.subject =~ /ONS Dataset Topic updated/ && email.body =~ /#{@dataset_topic.title}/m
        end
      end
    end
  end
end
