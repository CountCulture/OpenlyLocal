require File.dirname(__FILE__) + '/../test_helper'
require 'nokogiri'

# Tests IcalUtilities::Calendar class. NB uses Mocha
class NessUtilitiesTest < ActiveSupport::TestCase

  context "A RawClient instance" do
    setup do
      @client = NessUtilities::RawClient.new('FooMethod')
    end

    should "extract service from submitted params" do

    end

    should "use submitted params in request" do

    end

    should "use given method in request" do

    end

    context "when processing and extracting datapoints" do
      should "process" do
        @client.expects(:process)
        @client.process_and_extract_datapoints
      end

      should "extract datapoints" do
        @client.expects(:extract_datapoints)
        @client.process_and_extract_datapoints
      end
    end

    context "extracting datapoints from XML response" do
      setup do
        @resp = Nokogiri.XML(dummy_xml_response(:ness_datapoints))
      end

      should "return nil if blank response submitted" do
        assert_nil @client.send(:extract_datapoints)
        assert_nil @client.send(:extract_datapoints, '')
      end

      should "return an array of hashes" do
        dps = @client.send(:extract_datapoints, @resp)
        assert_kind_of Array, dps
        assert_equal 2, dps.size
        assert_kind_of Hash, dps.first
      end

      should "return data from response" do
        dp = @client.send(:extract_datapoints, @resp).first
        assert_equal '2329', dp[:ons_dataset_topic_id]
        assert_equal '9709', dp[:value]
      end
    end

  end
end
