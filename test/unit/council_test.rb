require 'test_helper'

class CouncilTest < ActiveSupport::TestCase
  subject { @council }
  
  context "The Council class" do
    setup do
      @council = Factory(:council)
    end
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    should_have_many :members
    should_have_many :committees
    should_have_many :memberships
    should_have_many :scrapers
    should_have_many :meetings
    should_have_many :datapoints
    should_have_many :wards
    should_have_many :meeting_documents, :through => :meetings
    should_have_many :past_meeting_documents, :through => :held_meetings
    should_belong_to :portal_system
    should_have_db_column :notes
    should_have_db_column :wikipedia_url
    should_have_db_column :ons_url
    should_have_db_column :egr_id
    should_have_db_column :wdtk_name
    should_have_db_column :feed_url
    should_have_db_column :data_source_url
    should_have_db_column :data_source_name
    should_have_db_column :snac_id
    should_have_db_column :country
    should_have_db_column :population
    
    should "have parser named_scope" do
      expected_options = { :conditions => "members.council_id = councils.id", :joins => "INNER JOIN members", :group => "councils.id" }
      assert_equal expected_options, Council.parsed.proxy_options
    end
    
    should "return councils with members as parsed" do
      @another_council = Factory(:another_council)
      @member = Factory(:member, :council => @another_council)
      @another_member = Factory(:old_member, :council => @another_council) # add two members to @another council, @council has none
      assert_equal [@another_council], Council.parsed
    end
    
    should "have many datasets through datapoints" do
      @datapoint = Factory(:datapoint, :council => @council)
      assert_equal [@datapoint.dataset], @council.datasets
    end
    
    should "have many memberships through members" do
      @member = Factory(:member, :council => @council)
      Factory(:committee, :council => @council).members << @member
      assert_equal @member.memberships, @council.memberships
    end
    
    should "have many held meetings" do
      @committee = Factory(:committee, :council => @council)
      @held_meeting = Factory(:meeting, :council => @council, :committee => @committee)
      @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 2.weeks.from_now)
      assert_equal [@held_meeting], @council.held_meetings
    end
    
    context "when getting meeting_documents" do
      setup do
        @committee = Factory(:committee, :council => @council)
        @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 2.weeks.from_now)
        @document = Factory(:document, :document_owner => @forthcoming_meeting)
      end

      should "not return document body or raw_body" do
        assert !@council.meeting_documents.first.attributes.include?("body")
        assert !@council.meeting_documents.first.attributes.include?("raw_body")
      end
    end
    
  end
  
  context "A Council instance" do
    setup do
      @council = Factory(:council)
    end

    should "alias name as title" do
      assert_equal @council.name, @council.title
    end
    
    should "return url as base_url if base_url is not set" do
      assert_equal @council.url, @council.base_url
    end
    
    should "return base_url as base_url if base_url is set" do
      council = Factory(:another_council, :base_url => "another.url")
      assert_equal "another.url", council.base_url
    end
    
    should "include title in to_param method" do
      @council.name = "some title-with/stuff"
      assert_equal "#{@council.id}-some-title-with-stuff", @council.to_param
    end
    
    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @council.foaf_telephone
      end
      
      should "return formatted number" do
        @council.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @council.foaf_telephone
      end
    end
    
    context "when returning dbpedia_url" do

      should "return nil if wikipedia_url blank" do
        assert_nil @council.dbpedia_url
      end
      
      should "return dbpedia url" do
        @council.wikipedia_url = "http://en.wikipedia.org/wiki/Herefordshire"
        assert_equal "http://dbpedia.org/page/Herefordshire", @council.dbpedia_url
      end
    end
    
    context "when returning authority_type_help_url" do

      should "return nil if authority_type blank" do
        assert_nil @council.authority_type_help_url
      end
      
      should "return appropriate wiki url for authority type" do
        @council.authority_type = "Unitary"
        assert_equal "http://en.wikipedia.org/wiki/Unitary_authority", @council.authority_type_help_url
      end
      
      should "return nil if no known wiki url for authority_type" do
        @council.authority_type = "foo"
        assert_nil @council.authority_type_help_url
      end
    end
    
    should "be considered parsed if it has members" do
      Factory(:member, :council => @council)
      assert @council.parsed?
    end
    
    should "be considered unparsed if it has no members" do
      assert !@council.parsed?
    end
    
    context "when returning openlylocal_url" do
      should "build from council.to_param and default domain" do
        assert_equal "http://#{DefaultDomain}/councils/#{@council.to_param}", @council.openlylocal_url
      end
    end
    
    context "when converting council to_xml" do
      should "not include base_url" do
        assert_no_match %r(<base-url), @council.to_xml
      end
      
      should "include openlylocal_url" do
        assert_match %r(<openlylocal-url), @council.to_xml
      end
      
      should "not include portal_system_id" do
        assert_no_match %r(<portal-system-id), @council.to_xml
      end
    end
    
    context "when converting council to_detailed_xml" do
      setup do
        member = Factory(:member, :council => @council)
        datapoint = Factory(:datapoint, :council => @council)
        Factory(:committee, :council => @council)
        Factory(:ward, :council => @council)
      end
      
      should "not include base_url" do
        assert_no_match %r(<base-url), @council.to_detailed_xml
      end
      
      should "include openlylocal_url" do
        assert_match %r(<openlylocal-url), @council.to_detailed_xml
      end
      
      should "not include portal_system_id" do
        assert_no_match %r(<portal-system-id), @council.to_detailed_xml
      end
      
      should "include member ids" do
        assert_match %r(<member.+<id.+</member)m, @council.to_detailed_xml
      end
      
      should "include member names" do
        assert_match %r(<member.+<first-name.+</member)m, @council.to_detailed_xml
      end
      
      should "not include member emails" do
        assert_no_match %r(<member.+<email.+</member)m, @council.to_detailed_xml
      end
      
      should "include dataset ids" do
        assert_match %r(<dataset.+<id.+</dataset)m, @council.to_detailed_xml
      end
      
      should "include committee ids" do
        assert_match %r(<committee.+<id.+</committee)m, @council.to_detailed_xml
      end
      
      should "include wards ids" do
        assert_match %r(<ward.+<id.+</ward)m, @council.to_detailed_xml
      end
    end
    
    context "when returning party breakdown" do

      should "return empty array if no members" do
        assert_equal [], Council.new.party_breakdown
      end
      
      should "calculate breakdown from members list" do
        dummy_members = [stub(:party => "Conservative")]*3 + [stub(:party => "Labour")]*6 + [stub(:party => "Independent")]
        @council.expects(:members).returns(dummy_members)
        assert_equal [["Labour", 6], ["Conservative", 3],["Independent", 1]], @council.party_breakdown
      end
      
      should "return empty array if no party details for any members" do
        dummy_members = [stub(:party => nil)]*3
        @council.expects(:members).returns(dummy_members)
        assert_equal [], @council.party_breakdown
      end
      
      should "return 'not known' for members with no party" do
        dummy_members = [stub(:party => "Conservative")]*3 + [stub(:party => nil)]
        @council.expects(:members).returns(dummy_members)
        assert_equal [["Conservative", 3],["Not known", 1]], @council.party_breakdown
      end
      
      should "return 'not known' for members with blank party" do
        dummy_members = [stub(:party => "Conservative")]*3 + [stub(:party => "")]
        @council.expects(:members).returns(dummy_members)
        assert_equal [["Conservative", 3],["Not known", 1]], @council.party_breakdown
      end
      
      should "return 'not known' for members with blank and nil parties" do
        dummy_members = [stub(:party => "Conservative")]*3 + [stub(:party => "")] + [stub(:party => nil)]
        @council.expects(:members).returns(dummy_members)
        assert_equal [["Conservative", 3],["Not known", 2]], @council.party_breakdown
      end
    end
    
    should "return name without Borough etc as short_name" do
      assert_equal "Brent", Council.new(:name => "London Borough of Brent").short_name
      assert_equal "Westminster", Council.new(:name => "City of Westminster").short_name
      assert_equal "Leeds", Council.new(:name => "Leeds City Council").short_name
      assert_equal "Kingston upon Thames", Council.new(:name => "Royal Borough of Kingston upon Thames").short_name
    end
    
    context "when returning average committee memberships" do
      setup do
        3.times do |i|
          instance_variable_set("@committee_#{i+1}", Factory(:committee, :council => @council))
          instance_variable_set("@member_#{i+1}", Factory(:member, :council => @council))
        end
        @committee_1.members << [@member_1, @member_2, @member_3]
        @committee_2.members << [@member_2, @member_3]
        @committee_3.members << [@member_3]
      end

      should "calculate mean" do
        assert_equal 2, @council.average_membership_count
      end
      
      # should "exclude past members" do
      #   @member_1.update_attribute(:date_left, 3.days.ago)
      #   assert_in_delta 5.0/2, @council.average_membership_count, 2 ** -20
      # end
    end
    
  end
  
end
