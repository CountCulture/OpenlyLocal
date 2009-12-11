require File.dirname(__FILE__) + '/../test_helper'
require 'nokogiri'

# Tests IcalUtilities::Calendar class. NB uses Mocha
class NessUtilitiesTest < ActiveSupport::TestCase

  context "A RawClient instance" do
    setup do
      @client = NessUtilities::RawClient.new('FooMethod', [[:foo, 'bar'], [:foobar, [42,213]]])
    end

    should "use submitted params in request" do

    end

    should "use given method in request" do

    end

    should "set service to discovery by default" do
      assert_equal "discoverystructs", @client.ness_service
      assert_equal "dis", @client.ness_ns
      assert_equal "/interop/NeSSDiscoveryBindingPort", @client.ns_path
    end

    context "when setting service to delivery" do
      should "change ness_service settings to discovery" do
        @client.service = 'delivery'
        assert_equal "deliveryservice", @client.ness_service
        assert_equal "del", @client.ness_ns
        assert_equal "/interop/NeSSDeliveryBindingPort", @client.ns_path
      end
    end

    context "when building request" do

      should "use client params for body of request" do
        body = Nokogiri.XML(@client.send(:build_request)).at('soapenv|Body').to_s
        assert_match %r(<dis:foo>bar<\/dis:foo>), body.to_s
      end

      should "convert arrays in params to comma separeted list" do
        body = Nokogiri.XML(@client.send(:build_request)).at('soapenv|Body').to_s
        assert_match %r(<dis:foobar>42,213<\/dis:foobar>), body.to_s
      end

      should "add additional params in body of request" do
        body = Nokogiri.XML(@client.send(:build_request, [[:foo1, 'baz']])).at('soapenv|Body').to_s
        assert_match %r(<dis:foo>bar<\/dis:foo>), body.to_s
        assert_match %r(<dis:foo1>baz<\/dis:foo1>), body.to_s
      end
    end

    context "when processing" do
      should "build request params" do
        @client.expects(:build_request)
        @client.process
      end

      should "pass on additional params when building request params" do
        @client.expects(:build_request).with([[:foo1, 'baz']])
        @client.process([[:foo1, 'baz']])
      end

      should "post built request" do
        @client.stubs(:build_request).returns('foobar')
        @client.expects(:_http_post).with('foobar')
        @client.process
      end

      should "return Nokogiri version of response" do
        dummy_xml = '<root><foo>bar</foo></root>'
        @client.stubs(:_http_post).returns(dummy_xml)
        resp = @client.process
        assert_kind_of Nokogiri::XML::Document, resp
        assert_equal Nokogiri.XML(dummy_xml).to_s, resp.to_s
      end

    end

    context "when processing and extracting datapoints" do

      should "set service to delivery" do
        @client.process_and_extract_datapoints
        assert_equal 'deliveryservice', @client.ness_service
      end

      should "process without grouping by dataset " do
        @client.expects(:process).with([['GroupByDataset', 'No']])
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
        assert_equal '2329', dp[:ness_topic_id]
        assert_equal '9709', dp[:value]
      end
    end

    context "extracting datapoints from XML response not grouped by dataset" do
      setup do
        @resp = Nokogiri.XML(dummy_xml_response(:ness_child_area_tables_response))
      end

      should "return an array of hashes" do
        dps = @client.send(:extract_datapoints, @resp)
        assert_kind_of Array, dps
        assert_equal 40, dps.size # 20 wards, two topics
        assert_kind_of Hash, dps.first
      end

      should "return data from response" do
        dps = @client.send(:extract_datapoints, @resp)
        assert dps_for_area = dps.find_all {|dp| dp[:ness_area_id] == '6114051'}.sort_by{|dp| dp[:ness_topic_id].to_i}
        assert_equal 2, dps_for_area.size
        assert_equal '37.54', dps_for_area.first[:value]
        assert_equal '63', dps_for_area.first[:ness_topic_id]
        assert_equal '9202', dps_for_area.last[:value]
        assert_equal '2329', dps_for_area.last[:ness_topic_id]
      end
    end

  end
end
