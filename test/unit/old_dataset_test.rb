require 'test_helper'

class OldDatasetTest < ActiveSupport::TestCase
  subject { @dataset }
  
  context "The OldDataset class" do
    setup do
      @dataset = Factory(:old_dataset) 
    end

    should_have_db_columns :title, :source, :key, :query, :description, :originator, :originator_url, :summary_column, :last_checked
    should_validate_presence_of :title, :key, :query
    should have_many :old_datapoints

    should "have base_url" do
      assert_match /spreadsheets.google/, OldDataset::BASE_URL
    end
    
    should "should return stale datasets" do
      @fresh_dataset = Factory(:old_dataset, :key => "foo123", :last_checked => 6.days.ago)
      @stale_dataset = Factory(:old_dataset, :key => "bar456", :last_checked => 8.days.ago)
      stale_datasets = OldDataset.stale
      
      assert_equal 2, stale_datasets.size
      
      assert stale_datasets.include?(@stale_dataset)
      assert stale_datasets.include?(@dataset)
      assert !stale_datasets.include?(@fresh_dataset)
    end
    
  end
  
  context "A OldDataset instance" do
    setup do
      @dataset = Factory.create(:old_dataset, :query => "select A,B,C,D,E,F,G")
      @council = Factory(:council)
      @another_council = Factory(:another_council)
    end

    should_validate_uniqueness_of :key
    
    should "constuct public_url from key" do
      assert_equal "http://spreadsheets.google.com/pub?key=abc123", @dataset.public_url
    end
    
    should "build query_url from query, key when no council given" do
      @council.stubs(:short_name).returns("Foo bar")
      assert_equal 'http://spreadsheets.google.com/tq?tqx=out:csv&tq=select+A%2CB%2CC%2CD%2CE%2CF%2CG&key=abc123', @dataset.query_url
    end
    
    should "build query_url from query, key and council short title" do
      @council.stubs(:short_name).returns("Foo bar")
      assert_equal 'http://spreadsheets.google.com/tq?tqx=out:csv&tq=select+A%2CB%2CC%2CD%2CE%2CF%2CG+where+A+contains+%27Foo+bar%27&key=abc123', @dataset.query_url(@council)
    end
    
    context "when processing" do
      setup do
        @csv_response = "\"LOCAL AUTHORITY\",\"Authority Type\"\n\"Bristol City \",\"UA\"\n\"Anytown Council\",\"LB\""
        @dataset.stubs(:query_url).returns("some_url")
        @dataset.stubs(:_http_get).returns(@csv_response)
      end

      should "build query_url" do
        @dataset.expects(:query_url)
        @dataset.process
      end
      
      should "get data from query_url" do
        @dataset.expects(:_http_get).with("some_url").returns(@csv_response)
        @dataset.process
      end
      
      should "parse csv data" do
        FasterCSV.expects(:parse).with(@csv_response, anything).returns([["LOCAL AUTHORITY"],["Anytown Council"]])
        @dataset.process
      end
      
      should "return nil if no data found" do
        @dataset.expects(:_http_get).returns(nil) # using expects overrides stubbing
        assert_nil @dataset.process
      end
      
      should "save data as datapoints for matching councils" do
        old_count = OldDatapoint.count
        @dataset.process
        assert_equal old_count+1, OldDatapoint.count
      end
      
      should "associate datapoint with council" do
        @dataset.process
        assert_equal @council, OldDatapoint.find(:first, :order => "id DESC").council
      end
      
      should "associate datapoint with dataset" do
        @dataset.process
        assert_equal @dataset, OldDatapoint.find(:first, :order => "id DESC").old_dataset
      end
      
      should "save data as datapoint data for council" do
        @dataset.process
        assert_equal [["LOCAL AUTHORITY", "Authority Type"], ["Anytown Council", "LB"]], @council.old_datapoints.find(:first, :order => "id DESC").data
      end
      
      should "update last_checked timestamp" do
        @dataset.process
        assert_in_delta Time.now, @dataset.reload.last_checked, 2
      end
      
      should "not update updated_at timestamp" do
        OldDataset.record_timestamps = false # update timestamp without triggering callbacks
        @dataset.update_attribute(:updated_at, 2.hours.ago)
        OldDataset.record_timestamps = true 
        
        @dataset.process
        assert_in_delta 2.hours.ago, @dataset.updated_at, 2
        
      end
      
      context "and datapoint already exists for council and dataset" do
        setup do
          @old_datapoint = Factory(:old_datapoint, :council => @council, :old_dataset => @dataset)
        end
        
        should "not create new datapoint" do
          old_count = OldDatapoint.count
          @dataset.process
          assert_equal old_count, OldDatapoint.count
        end

        should "update data for datapoint" do
          @dataset.process
          assert_equal [["LOCAL AUTHORITY", "Authority Type"], ["Anytown Council", "LB"]], @old_datapoint.reload.data
        end
      end
      
    end
    
    context "when getting data for council" do
      setup do
        @csv_response = "\"LOCAL AUTHORITY\",\"Authority Type\"\n\"Bristol City \",\"UA\""
        @dataset.stubs(:query_url).returns("some_url")
        @dataset.stubs(:_http_get).returns(@csv_response)
      end

      should "build query_url using council" do
        @dataset.expects(:query_url).with(@council)
        @dataset.data_for(@council)
      end
      
      should "get data from query_url" do
        @dataset.expects(:_http_get).with("some_url").returns(@csv_response)
        @dataset.data_for(@council)
      end
      
      should "parse csv data into ruby array" do
        parsed_response = [["LOCAL AUTHORITY", "Bristol City "], ["Authority Type", "UA"]]
        assert_equal parsed_response, @dataset.data_for(@council)
      end
      
      should "return nil if no data found" do
        @dataset.expects(:_http_get).returns(nil) # using expects overrides stubbing
        assert_nil @dataset.data_for(@council)
      end
    end
    
  end
end
