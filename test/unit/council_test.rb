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
    should_have_many :officers
    should_have_many :services
    should_have_many :child_authorities
    should_have_many :meeting_documents, :through => :meetings
    should_have_many :past_meeting_documents, :through => :held_meetings
    should_have_one :police_authority, :through => :police_force
    should_have_one :chief_executive
    should_belong_to :parent_authority
    should_belong_to :portal_system
    should_belong_to :police_force
    should_have_many :ons_datapoints
    should_have_many :ons_dataset_topics, :through => :ons_datapoints
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
    should_have_db_column :twitter_account
    should_have_db_column :ldg_id
    should_have_db_column :police_force_url

    should "mixin PartyBreakdownSummary module" do
      assert Council.new.respond_to?(:party_breakdown)
    end

    context "parsed named_scope" do
      should "pass on parsed conditions" do
        expected_options = { :conditions => "members.council_id = councils.id", :joins => "INNER JOIN members", :group => "councils.id" }
        assert_equal expected_options, Council.parsed({}).proxy_options
      end

      should "return councils with members as parsed" do
        @another_council = Factory(:another_council)
        @member = Factory(:member, :council => @another_council)
        @another_member = Factory(:old_member, :council => @another_council) # add two members to @another council, @council has none
        assert_equal [@another_council], Council.parsed({})
      end

      should "include unparsed councils with parsed if requested" do
        @another_council = Factory(:another_council)
        @member = Factory(:member, :council => @another_council)
        assert_equal [@another_council, @council], Council.parsed(:include_unparsed => true)
      end
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

    context "when finding by parameters" do
      setup do
        @member = Factory(:member, :council => @council)
        @another_council = Factory(:another_council, :snac_id => "snac_1")
        @another_member = Factory(:member, :council => @another_council)
        @tricky_council = Factory(:tricky_council, :snac_id => "snac_2")
      end

      should "find all parsed councils by default" do
        assert_equal [@another_council, @council], Council.find_by_params
      end

      should "find unparsed councils by if requested" do
        assert_equal [@another_council, @council, @tricky_council], Council.find_by_params(:include_unparsed => true)
      end

      should "find parsed councils whose name matches term" do
        assert_equal [@another_council], Council.find_by_params(:term => "not") # @another_council name is 'Another council'
        assert_equal [@another_council, @council], Council.find_by_params(:term => "An")
      end

      should "find unparsed councils whose name matches term" do
        assert_equal [@tricky_council], Council.find_by_params(:term => "Tricky", :include_unparsed => true)
      end

      should "find parsed council whose snac_id matches given id" do
        assert_equal [@another_council], Council.find_by_params(:snac_id => "snac_1")
      end

      should "find unparsed council whose snac_id matches given id" do
        assert_equal [@tricky_council], Council.find_by_params(:snac_id => "snac_2", :include_unparsed => true)
        assert_equal [], Council.find_by_params(:snac_id => "snac_2")
      end
    end

    context "when finding councils with stale services" do
      setup do
        # @council has no ldg_id
        @council_with_no_services = Factory(:council, :ldg_id => 21, :name => "council_with_no_services")
        @council_with_stale_services = Factory(:council, :ldg_id => 22, :name => "council_with_stale_services")
        @council_with_fresh_services = Factory(:council, :ldg_id => 23, :name => "council_with_fresh_services")

        @service = Factory(:service, :council => @council_with_fresh_services) #fresh

        Service.record_timestamps = false
        @service = Factory(:service, :council => @council_with_stale_services, :updated_at => 2.weeks.ago, :created_at => 2.weeks.ago) #stale
        @service = Factory(:service, :council => @council_with_stale_services, :updated_at => 2.weeks.ago, :created_at => 2.weeks.ago) #stale
        Service.record_timestamps = true
      end

      should "return councils with ldg_id and stale services" do
        assert_equal [@council_with_no_services, @council_with_stale_services], Council.with_stale_services
      end

      should "return council with several stale services just once" do
        assert_equal 1, Council.with_stale_services.select{ |c| c == @council_with_stale_services }.size
      end
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

    should "have one chief executive" do
      non_ceo = Factory(:officer, :council => @council)
      ceo = Factory(:officer, :position => "Chief Executive", :council => @council)
      assert_equal ceo, @council.chief_executive
    end

    context "when getting potential_services" do
      setup do
        @service = Factory(:ldg_service) # this service is provided by district and unitary councils only
        @full_service = Factory(:ldg_service, :authority_level => "all", :service_name => "bar service") # this service is provided by all councils only
        @unitary_service = Factory(:ldg_service, :authority_level => "unitary", :service_name => "baz Service") # this service is provided by county councils only
        @council.ldg_id = 42
      end

      should "get services that council provides" do
        @council.authority_type = "District"
        assert_equal [@service, @full_service], @council.potential_services
        @council.authority_type = "Unitary"
        assert_equal [@service, @full_service, @unitary_service], @council.potential_services
      end

      should "treat london boroughs and metropolitan boroughs as unitary councils" do
        @council.authority_type = "London Borough"
        assert_equal [@service, @full_service, @unitary_service], @council.potential_services
        @council.authority_type = "Metropolitan Borough"
        assert_equal [@service, @full_service, @unitary_service], @council.potential_services
      end

      should "not get services that council does not provide" do
        @council.authority_type = "County"
        assert_equal [@full_service], @council.potential_services
      end

      should "return no results if council does not have lgd_id" do
        @council.ldg_id = nil
        @council.authority_type = "District"
        assert_equal [], @council.potential_services
      end

      # should "get services that council provides and match given term" do
      #   @council.authority_type = "Unitary"
      #   assert_equal [@full_service], @council.services(:term => "bar")
      #   assert_equal [@service, @full_service, @unitary_service], @council.services(:term => "service") # case insensitive
      # end
    end
    
    context "when getting grouped datapoints" do
      setup do
        @data_grouping_in_words = Factory(:dataset_topic_grouping, :title => "misc", :display_as => "in_words")
        @data_grouping_as_graph = Factory(:dataset_topic_grouping, :title => "demographics", :display_as => "graph")
        @basic_data_grouping = Factory(:dataset_topic_grouping, :title => "spending")
        @unused_data_grouping = Factory(:dataset_topic_grouping, :title => "foo")
        @another_council = Factory(:council, :name => "Another council")
        
        @selected_topic_1 = Factory(:ons_dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "b title")
        @selected_topic_2 = Factory(:ons_dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "a title")
        @selected_topic_3 = Factory(:ons_dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "c title")
        @selected_topic_4 = Factory(:ons_dataset_topic, :dataset_topic_grouping => @data_grouping_in_words)
        @selected_topic_5 = Factory(:ons_dataset_topic, :dataset_topic_grouping => @data_grouping_as_graph)
        @unselected_topic = Factory(:ons_dataset_topic)
        @selected_dp_1 = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @selected_topic_1, :value => "3.99")
        @selected_dp_2 = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @selected_topic_2, :value => "4.99")
        @selected_dp_3 = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @selected_topic_3, :value => "2.99")
        @selected_dp_4 = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @selected_topic_4)
        @selected_dp_5 = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @selected_topic_5)
        @unselected_dp = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @unselected_topic)
        @wrong_council_dp = Factory(:ons_datapoint, :area => @another_council, :ons_dataset_topic => @selected_topic_1)
      end

      should "return hash of arrays" do
        assert_kind_of ActiveSupport::OrderedHash, @council.grouped_datapoints
        assert_kind_of Array, @council.grouped_datapoints.values.first
      end

      should "use data groupings as keys" do
        assert @council.grouped_datapoints.keys.include?(@basic_data_grouping)
      end

      should "return datapoints for topics in groupings" do
        assert @council.grouped_datapoints.values.flatten.include?(@selected_dp_1)
      end

      should "not return datapoints with topics not in groupings" do
        assert !@council.grouped_datapoints.values.flatten.include?(@unselected_dp)
      end
      
      should "return in_words groupings first" do
        assert_equal @data_grouping_in_words, @council.grouped_datapoints.keys.first
      end
      
      should "return graph groupings next" do
        assert_equal @data_grouping_as_graph, @council.grouped_datapoints.keys[1]
      end
      
      should "return other groupings last" do
        assert_equal @basic_data_grouping, @council.grouped_datapoints.keys.last
      end
      
      should "not return groupings with no data" do
        assert_nil @council.grouped_datapoints[@unused_data_grouping]
      end
      
      should "not return datapoints for different areas" do
        assert !@council.grouped_datapoints.values.flatten.include?(@wrong_council_dp)
      end
      
      should "sort by associated topic order by default" do
        assert_equal @selected_dp_2, @council.grouped_datapoints[@basic_data_grouping].first
      end
      
      should "return sorted if data_grouping has sort_by set" do
        @basic_data_grouping.update_attribute(:sort_by, "value")
        assert_equal @selected_dp_3, @council.grouped_datapoints[@basic_data_grouping].first
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

    should "return url as base_url if base_url is empty_string" do
      @council.base_url = ""
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

    context "when returning dbpedia_resource" do

      should "return nil if wikipedia_url blank" do
        assert_nil @council.dbpedia_resource
      end

      should "return dbpedia url" do
        @council.wikipedia_url = "http://en.wikipedia.org/wiki/Herefordshire"
        assert_equal "http://dbpedia.org/resource/Herefordshire", @council.dbpedia_resource
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

    should "return parsed status as status" do
      assert_equal "unparsed", @council.status
      @council.stubs(:parsed?).returns(true)
      assert_equal "parsed", @council.status
    end

    context "when returning openlylocal_url" do
      should "build from council.to_param and default domain" do
        assert_equal "http://#{DefaultDomain}/councils/#{@council.to_param}", @council.openlylocal_url
      end
    end

    context "when returning police_force_url" do
      setup do
        @force = Factory(:police_force)
      end

      should "return police_force_url if set and police_force is not" do
        @council.update_attribute(:police_force_url, "http://police.com/anytown")
        assert_equal "http://police.com/anytown", @council.police_force_url
      end

      should "return police_force_url if set and police_force is" do
        @council.update_attribute(:police_force_url, "http://police.com/anytown")
        @council.update_attribute(:police_force_id, @force.id)
        assert_equal "http://police.com/anytown", @council.police_force_url
      end

      should "return assoc police_force url if police_force_url blank" do
        @council.update_attribute(:police_force_id, @force.id)
        assert_equal @force.url, @council.police_force_url
      end

      should "return nil if no assoc police_force and police_force_url blank" do
        assert_nil @council.police_force_url
      end
    end

    context "when getting active_committees" do
      setup do
        @committee = Factory(:committee, :council => @council)
        @another_committee = Factory(:committee, :council => @council)
      end

      should "return active committees if they exist" do
        Factory(:meeting, :council => @council, :committee => @committee)
        assert_equal [@committee], @council.active_committees
      end

      should "return all committees if no active committees" do
        assert_equal [@committee, @another_committee], @council.active_committees
      end

      should "include inactive committees if requested" do
        Factory(:meeting, :council => @council, :committee => @committee)
        assert_equal [@committee, @another_committee], @council.active_committees(true)
      end

      should "include activity status when including inactive committees" do
        Factory(:meeting, :council => @council, :committee => @committee)
        assert @council.active_committees(true).first.respond_to?(:active?)
      end
    end

    context "when calculating whether council has active committees" do
      setup do
        @committee = Factory(:committee, :council => @council)
        @another_committee = Factory(:committee, :council => @council)
      end

      should "return true if council has meetings" do
        Factory(:meeting, :council => @council, :committee => @committee)
        assert @council.active_committees?
      end
      should "return false if council has no meetings" do
        assert !@council.active_committees?
      end

      should "return false if council has only very old meetings" do
        Factory(:meeting, :council => @council, :committee => @committee, :date_held => 13.months.ago)
        assert !@council.active_committees?
      end
    end

    context "when returning related" do
      
      should "return councils of same authority_type" do
        @council.update_attribute(:authority_type, "District")
        @related_council = Factory(:council, :name => "related_council", :authority_type => "District")
        @unrelated_council = Factory(:council, :name => "unrelated_council", :authority_type => "Unitary")
        assert_equal [@council, @related_council], @council.related
      end
    end
    
    context "when getting recent activity" do
      setup do
        @member = Factory(:member, :council => @council)
        @old_member = Factory(:member, :council => @council)
        @committee = Factory(:committee, :council => @council)
        @old_committee = Factory(:committee, :council => @council)
        @meeting = Factory(:meeting, :council => @council, :committee => @committee)
        @old_meeting = Factory(:meeting, :council => @council, :committee => @committee)
        @document = Factory(:document, :document_owner => @meeting)
        @old_document = Factory(:document, :document_owner => @meeting)
        %w(member committee meeting document).each do |kind|
          kind_klass = kind.classify.constantize
          kind_klass.record_timestamps = false
          instance_variable_get("@old_#{kind}").update_attribute(:updated_at, 8.days.ago)
          kind_klass.record_timestamps = true
        end
      end

      should "return hash of activity" do
        assert_kind_of Hash, @council.recent_activity
      end

      should "return most recently updated members" do
        assert_equal [@member], @council.recent_activity[:members]
      end

      should "return most recently updated committees" do
        assert_equal [@committee], @council.recent_activity[:committees]
      end

      should "return most recently updated meetings" do
        assert_equal [@meeting], @council.recent_activity[:meetings]
      end

      should "return most recently updated documents" do
        assert_equal [@document], @council.recent_activity[:documents]
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
        @member = Factory(:member, :council => @council, :party => "foobar")
        datapoint = Factory(:datapoint, :council => @council)
        @committee = Factory(:committee, :council => @council)
        mark_as_stale(@committee)
        @updated_committee = Factory(:committee, :council => @council)
        @old_member = Factory(:member, :council => @council, :email => "old_email@test.com")
        mark_as_stale(@old_member)
        @past_meeting = Factory(:meeting, :council => @council, :committee => @committee)
        mark_as_stale(@past_meeting)
        @future_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 3.days.from_now, :created_at  => 1.month.ago, :updated_at  => 1.month.ago)
        mark_as_stale(@future_meeting)
        @updated_past_meeting = Factory(:meeting, :council => @council, :committee => @committee)
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

      should "include member party" do
        assert_match %r(<member.+<party>foobar.+</member)m, @council.to_detailed_xml
      end

      should "include member urls" do
        assert_match %r(<member.+<url>#{@member.url}.+</url)m, @council.to_detailed_xml
      end

      should "not include member emails" do
        assert_no_match %r(<member.+<email>#{@old_member.email}.+</member)m, @council.to_detailed_xml
      end

      should "include dataset ids" do
        assert_match %r(<dataset.+<id.+</dataset)m, @council.to_detailed_xml
      end

      should "include committee ids" do
        assert_match %r(<committee.+<id.+</committee)m, @council.to_detailed_xml
      end

      should "include committee urls" do
        assert_match %r(<committee.+<url>#{@committee.url}</url.+</committee)m, @council.to_detailed_xml
      end

      should "include committee openlylocal urls" do
        assert_match %r(<committee.+<openlylocal-url>#{@committee.openlylocal_url}</openlylocal.+</committee)m, @council.to_detailed_xml
      end

      should "include forthcoming meeting ids" do
        assert_match %r(<meeting.+<id type=\"integer\">#{@future_meeting.id}</id.+</meeting)m, @council.to_detailed_xml
      end

      should "include forthcoming meeting formatted_date" do
        assert_match %r(<meeting.+<formatted-date>#{@future_meeting.formatted_date}.+</meeting.+<recent-activity)m, @council.to_detailed_xml
      end

      should "exclude past meeting ids" do
        assert_no_match %r(<meeting.+<id type=\"integer\">#{@past_meeting.id}</id.+</meeting.+<recent-activity)m, @council.to_detailed_xml
      end

      should "include wards ids" do
        assert_match %r(<ward.+<id.+</ward)m, @council.to_detailed_xml
      end

      should "include recent activity" do
        assert_match %r(<recent-activity.+<member.+</recent-activity)m, @council.to_detailed_xml
      end

      should "include formatted meeting dates in recent activity" do
        assert_match %r(<recent-activity.+<meeting.+<formatted-date>#{@updated_past_meeting.formatted_date}.+</recent-activity)m, @council.to_detailed_xml
      end

      # should "include status of member in recent activity" do
      #   assert_match %r(<recent-activity.+<member.+<status.+</member.+</recent-activity)m, @council.to_detailed_xml
      # end
    end

    should "return name without Borough etc as short_name" do
      assert_equal "Brent", Council.new(:name => "London Borough of Brent").short_name
      assert_equal "Westminster", Council.new(:name => "City of Westminster").short_name
      assert_equal "Leeds", Council.new(:name => "Leeds City Council").short_name
      assert_equal "Kingston upon Thames", Council.new(:name => "Royal Borough of Kingston upon Thames").short_name
      assert_equal "Wolverhampton", Council.new(:name => "Wolverhampton Metropolitan Borough Council").short_name
      assert_equal "City of London", Council.new(:name => "City of London").short_name
      assert_equal "Greater London Authority", Council.new(:name => "Greater London Authority").short_name
      assert_equal "Greater London Authority", Council.new(:name => "Greater London Authority").short_name
      assert_equal "Vale of White Horse", Council.new(:name => "Vale of White Horse District Council").short_name
      assert_equal "Wrexham", Council.new(:name => "Wrexham County Borough Council").short_name
      assert_equal "Comhairle nan Eilean Siar", Council.new(:name => "Comhairle nan Eilean Siar (Western Isles Council)").short_name
      assert_equal "Swansea", Council.new(:name => "City & County of Swansea").short_name
      assert_equal "Kensington Chelsea", Council.new(:name => "Royal Borough of Kensington & Chelsea").short_name
      assert_equal "Tonbridge Malling", Council.new(:name => "Tonbridge and Malling Borough Council").short_name
      assert_equal "Fenland", Council.new(:name => "Fenland District Council").short_name
      assert_equal "Isles of Scilly", Council.new(:name => "Council of the Isles of Scilly").short_name
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


  private
  def mark_as_stale(rec)
    rec.class.record_timestamps = false
    rec.update_attributes(:created_at => 2.months.ago, :updated_at => 2.months.ago)
    rec.class.record_timestamps = true
  end
  
end
