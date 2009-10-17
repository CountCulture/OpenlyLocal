require 'test_helper'

class CachedPostcodeTest < ActiveSupport::TestCase
  subject { @cached_postcode }
  context "The CachedPostcode class" do
    setup do
      @cached_postcode = Factory(:cached_postcode) # code by default is
    end
    
    should_validate_uniqueness_of :code
    should_belong_to :output_area
    # should_belong_to :council
    # should_belong_to :ward
    # should_belong_to :output_area
    
    should "save postcode code as upper-case string without spaces" do
      assert_equal "AB2EF7", CachedPostcode.new(:code => "AB2 EF7").code
      assert_equal "AB2EF7", CachedPostcode.new(:code => "A B2 EF 7").code
      assert_equal "AB2EF7", CachedPostcode.new(:code => "ab2Ef7").code
      assert_equal "AB2EF7", CachedPostcode.new(:code => "ab2 ef 7").code
    end
    
    context "when finding postcode" do
      context "and it is in db" do
        should "return cached_postcode for normalized string if it is in db" do
          cp = Factory(:cached_postcode, :code => "AB1EF5")
          assert_equal cp, CachedPostcode.postcode_for("AB1EF5")
          assert_equal cp, CachedPostcode.postcode_for("ab1 ef5")
          assert_equal cp, CachedPostcode.postcode_for(" aB1 E f 5  ")
        end
      end
      
      context "and it is not in db" do
        setup do
          HTTPClient.any_instance.stubs(:get_content).returns(dummy_html_response :ons_output_area_from_postcode)
        end
        
        should "get output area info for given string from ONS" do
          HTTPClient.any_instance.expects(:get_content).with(regexp_matches(/statistics.gov.uk.+SearchText\=ab1\+ef5/)).returns(dummy_html_response :ons_output_area_from_postcode)
          CachedPostcode.postcode_for("ab1 ef5")
        end

        should "parse output area from response" do
          CachedPostcode.postcode_for("ab1 ef5")
        end
        
        should "follow link if told to because no session" do
          HTTPClient.any_instance.expects(:get_content).with(regexp_matches(/statistics.gov.uk.+SearchText\=ab1\+ef5/)).returns(dummy_html_response :ons_output_area_cookie_needed)
          HTTPClient.any_instance.expects(:get_content).with(regexp_matches(/statistics.gov.uk.+jessionid\=ac1f930b30d6fbb134a4e4574a9c8a54de54ef567189/)).returns(dummy_html_response :ons_output_area_from_postcode)
          CachedPostcode.postcode_for("ab1 ef5")
        end
        
        should "save postcode data" do
          assert_difference "CachedPostcode.count" do
            CachedPostcode.postcode_for("ab1 ef5")
          end
        end
        
        should "return newly added CachedPostcode" do
          assert_kind_of CachedPostcode, CachedPostcode.postcode_for("ab1 ef5")
          assert_equal "AB1EF5", CachedPostcode.postcode_for("ab1 ef5").code
        end
        
        should "not associate with output area if output area with oa_code does not exist" do
          CachedPostcode.postcode_for("ab1 ef5")
          assert_nil CachedPostcode.find_by_code("AB1EF5").output_area
        end
        
        should "associate with output area if output area with oa_code exists" do
          output_area = Factory(:output_area, :oa_code => "00AUGD0039")
          CachedPostcode.postcode_for("ab1 ef5")
          assert_equal output_area, CachedPostcode.find_by_code("AB1EF5").output_area
        end
      end
      
    end
  end
end
