require 'test_helper'

class CouncilTest < ActiveSupport::TestCase
  subject { @council }

  context "The Council class" do
    setup do
      @council = Factory(:council)
    end
    
    should_validate_presence_of :name
    should_validate_uniqueness_of :name
    should have_many :members
    should have_many :committees
    should have_many :memberships
    should have_many :scrapers
    should have_many :meetings
    should have_many :wards
    should have_many :officers
    should have_many :services
    should have_many :child_authorities
    should_have_many :meeting_documents, :through => :meetings
    should_have_many :past_meeting_documents, :through => :held_meetings
    should have_many :feed_entries
    should have_many :polls
    should_have_one :police_authority, :through => :police_force
    should have_one :chief_executive
    should belong_to :parent_authority
    should belong_to :portal_system
    should belong_to :police_force
    should belong_to :pension_fund
    should have_many :datapoints
    should_have_many :dataset_topics, :through => :datapoints
    should have_many :suppliers
    should_have_many :financial_transactions, :through => :suppliers
    should have_many :supplying_relationships
    should have_many :account_lines
    should have_db_column :notes
    should have_db_column :wikipedia_url
    should have_db_column :ons_url
    should have_db_column :egr_id
    should have_db_column :wdtk_name
    should have_db_column :feed_url
    should have_db_column :data_source_url
    should have_db_column :data_source_name
    should have_db_column :snac_id
    should have_db_column :country
    should have_db_column :population
    should have_db_column :ldg_id
    should have_db_column :police_force_url
    should have_db_column :region
    should have_db_column :signed_up_for_1010
    should have_db_column :annual_audit_letter
    should have_db_column :open_data_url
    should have_db_column :open_data_licence
    should have_db_column :normalised_title
    should have_db_column :vat_number

    should "mixin PartyBreakdownSummary module" do
      assert Council.new.respond_to?(:party_breakdown)
    end

    should "include TwitterAccountMethods mixin" do
      assert Council.new.respond_to?(:twitter_account_name)
    end
        
    should "include AreaMethods mixin" do
      assert Council.new.respond_to?(:grouped_datapoints)
    end
        
    should "mixin SpendingStat::Base module" do
      assert Council.new.respond_to?(:spending_stat)
    end

    context "should have parsed named_scope which" do
      setup do
        @another_council = Factory(:another_council)
        @member = Factory(:member, :council => @another_council)
        @another_member = Factory(:old_member, :council => @another_council) # add two members to @another council, @council has none
      end
      
      should "return councils with members as parsed" do
        assert_equal [@another_council], Council.parsed({})
      end

      should "include unparsed councils with parsed if requested" do
        assert_equal [@another_council, @council], Council.parsed(:include_unparsed => true)
      end
      
      should "return count of parsed council members as member_count attribute" do
        parsed_council = Council.parsed({}).first
        assert_equal "2", parsed_council.member_count
      end
      
      should "return zero as member_count attribute for unparsed councils" do
        unparsed_council = Council.parsed(:include_unparsed => true).last
        assert_equal "0", unparsed_council.member_count
      end
    end

    should "not include defunkt wards in wards association" do
      current_ward = Factory(:ward, :council => @council)
      defunkt_ward = Factory(:defunkt_ward, :council => @council)
      assert_equal [current_ward], @council.wards
    end

    should "have many memberships through members" do
      @member = Factory(:member, :council => @council)
      Factory(:committee, :council => @council).members << @member
      assert_equal @member.memberships, @council.memberships
    end
    
    should 'alias current members as members_for_party_breakdown' do
      Factory(:member, :council => @council)
      Factory(:member, :council => @council, :date_left => 5.days.ago)
      assert_equal @council.members.current, @council.members_for_party_breakdown
    end
    
    should "have many held meetings" do
      @committee = Factory(:committee, :council => @council)
      @held_meeting = Factory(:meeting, :council => @council, :committee => @committee)
      @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 2.weeks.from_now)
      assert_equal [@held_meeting], @council.held_meetings
    end

    should "have many hyperlocal sites" do
      approved_site = Factory(:approved_hyperlocal_site, :council => @council)
      approved_site_for_another_council = Factory(:approved_hyperlocal_site, :council => Factory(:another_council))
      unapproved_site = Factory(:hyperlocal_site, :council => @council)
      assert_equal [approved_site], @council.hyperlocal_sites
    end

    context "when finding by parameters" do
      setup do
        @member = Factory(:member, :council => @council)
        @another_council = Factory(:another_council, :region => "London", :country => "England")
        @another_member = Factory(:member, :council => @another_council)
        @council.update_attribute(:country, "Wales")
        @tricky_council = Factory(:tricky_council, :country => "Wales")
      end

      should "find all parsed councils by default" do
        assert_equal [@another_council, @council], Council.find_by_params
      end

      should "find unparsed councils if requested" do
        assert_equal [@another_council, @council, @tricky_council], Council.find_by_params(:include_unparsed => true)
      end

      should "find unparsed councils if requested to show_open_status" do
        assert_equal [@another_council, @council, @tricky_council], Council.find_by_params(:show_open_status => true)
      end

      should "find parsed councils whose name matches term" do
        assert_equal [@another_council], Council.find_by_params(:term => "not") # @another_council name is 'Another council'
        assert_equal [@another_council, @council], Council.find_by_params(:term => "An")
      end

      should "find unparsed councils whose name matches term" do
        assert_equal [@tricky_council], Council.find_by_params(:term => "Tricky", :include_unparsed => true)
      end

      should "find councils whose region matches given region" do
        assert_equal [@another_council], Council.find_by_params(:region => "London")
      end

      should "find councils whose region matches given country" do
        assert_equal [@council], Council.find_by_params(:country => "Wales")
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
    
    context "when getting councils without wards" do
      setup do
        ward = Factory(:ward, :council => @council)
        @council_without_wards = Factory(:another_council)
      end
      
      should "not return councils with wards" do
        assert !Council.without_wards.include?(@council)
      end
      
      
      should "return councils without wards" do
        assert Council.without_wards.include?(@council_without_wards)
      end
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
    
    context "when normalising title" do
      setup do
        @original_title_and_normalised_title = {
          "Edinburgh Council" => "edinburgh",
          "EDINBURGH COUNCIL" => "edinburgh",
          " EDINBURGH   COUNCIL    " => "edinburgh",
          "London Borough of Brent" => "brent",
          "City of Westminster" => "westminster",
          "Westminster City Council" => "westminster",
          "Leeds City Council" => "leeds",
          "Royal Borough of Kingston-upon Thames" => "kingston upon thames",
          "Wolverhampton Metropolitan Borough Council" => "wolverhampton",
          "City of London" => "city of london",
          "City of London Corporation" => "city of london",
          "Greater London Authority" => "greater london authority",
          "Vale of White Horse District Council" => "vale of white horse",
          "Wrexham County Borough Council" => "wrexham",
          "Derry (City of Londonderry)" => "derry",
          "Comhairle nan Eilean Siar (Western Isles Council)" => "comhairle nan eilean siar",
          "City & County of Swansea" => "swansea",
          "St. Albans" => "st albans",
          "Kingston upon Hull City Council" => "hull",
          "Kingston-upon-Hull City Council" => "hull",
          "Rotherham MBC" => "rotherham",
          "Lichfield City Council" => "lichfield city",
          "St Albans City and District Council" => "st albans",
          "Royal Borough of Kensington & Chelsea" => "kensington and chelsea",
          "Tonbridge and Malling Borough Council" => "tonbridge and malling",
          "Fenland District Council" => "fenland",
          "LB Brent" => "brent",
          "Selby Council" => "selby", #checking removing LB doesn't affect this
          "Council of the Isles of Scilly" => "isles of scilly"
        }
      end
      
      should "normalise title" do
        @original_title_and_normalised_title.each do |orig_title, normalised_title|
          assert_equal( normalised_title, Council.normalise_title(orig_title), "failed for #{orig_title}")
        end
      end
    end
    
    context "when returning cached_spending_data" do
      setup do
        # @suppliers = 2.times.collect{Factory(:supplier)}
        @companies = 3.times.collect{Factory(:company)}
        @financial_transactions = 5.times.collect{Factory(:financial_transaction)}
        @charities = 1.times.collect{Factory(:charity)}
        @spending_data = { :supplier_count=>77665, 
                           :largest_transactions=>@financial_transactions.collect(&:id), 
                           :largest_companies=>@companies.collect(&:id), 
                           :total_spend=>3404705734.99173, 
                           :company_count=>27204, 
                           :largest_charities=>@charities.collect(&:id), 
                           :transaction_count=>476422}
        
        YAML.stubs(:load_file).returns(@spending_data)
      end
      
      should "check for council_spending in data cache store" do
        YAML.expects(:load_file).with(File.join(RAILS_ROOT, 'db', 'data', 'cache', 'council_spending'))
        Council.cached_spending_data
      end
      
      should "return nil if no cached file" do
        YAML.expects(:load_file) # returns nil
        assert_nil Council.cached_spending_data
      end
            
      context "and council_spending_data is in cache" do

        should "return spending_data hash" do
          assert_kind_of Hash, Council.cached_spending_data
        end
        
        context "and Hash" do
          setup do
            @cached_spending_data = Council.cached_spending_data
          end

          should "replace financial_transaction_ids with financial_transactions" do
            assert_equal @financial_transactions, @cached_spending_data[:largest_transactions]
          end
          
          should "replace company ids with companies" do
            assert_equal @companies, @cached_spending_data[:largest_companies]
          end
          
          should "replace charity ids with charities" do
            assert_equal @charities, @cached_spending_data[:largest_charities]
          end
        end
      end
      
      context "and problem parsing YAML" do
        setup do
          YAML.expects(:load_file).raises
        end

        should "return nil" do
          assert_nil Council.cached_spending_data
        end
        
        should_eventually "email admin" do
          
        end
      end
      
    end
    
    context "when calculating spending_data" do

      should "calculate total council transaction count" do
        FinancialTransaction.expects(:count).with(:joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council'")
        Council.calculated_spending_data
      end
      
      should "calculate total council supplier count" do
        Supplier.expects(:count).with(:conditions => {:organisation_type => 'Council'})
        Council.calculated_spending_data
      end
      
      should "calculate total council companies count" do
        Company.expects(:count).with(:joins => :supplying_relationships, :conditions => 'suppliers.organisation_type = "Council"')
        Council.calculated_spending_data
      end
      
      should "calculate total value of council payments" do
        FinancialTransaction.expects(:sum).with(:value, :joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council'")
        Council.calculated_spending_data
      end
      
      should "find 20 largest payments" do
        FinancialTransaction.expects(:all).with(:order => 'value DESC', :limit => 20, :joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council'").returns([])
        Council.calculated_spending_data
      end
      
      should "find 20 largest company suppliers" do
        Company.expects(:all).with(:select => 'DISTINCT companies.id', :limit=>10, :joins => [:supplying_relationships, :spending_stat], :conditions => 'suppliers.organisation_type = "Council"', :order=>'spending_stats.total_spend DESC').returns([])
        Council.calculated_spending_data
      end
      
      should "find 20 largest charity suppliers" do
        Charity.expects(:all).with(:select => 'DISTINCT charities.id', :limit=>10, :joins => [:supplying_relationships, :spending_stat], :conditions => 'suppliers.organisation_type = "Council"', :order=>'spending_stats.total_spend DESC').returns([])
        Council.calculated_spending_data
      end
      
      should "return hash of calculated spending data" do
        assert_kind_of Hash, Council.calculated_spending_data
      end
      
      context "and hash" do
        setup do
          @company = Factory(:company)
          @charity = Factory(:charity)
          @financial_transaction = Factory(:financial_transaction)
          FinancialTransaction.stubs(:count).returns(42)
          Supplier.stubs(:count).returns(33)
          Company.stubs(:count).returns(21)
          FinancialTransaction.stubs(:sum).returns(424242)
          Company.stubs(:all).returns([@company])
          Charity.stubs(:all).returns([@charity])
          FinancialTransaction.stubs(:all).returns([@financial_transaction])
          @spending_data = Council.calculated_spending_data
        end

        should "include transaction_count" do
          assert_equal 42, @spending_data[:transaction_count]
        end

        should "include supplier_count" do
          assert_equal 33, @spending_data[:supplier_count]
        end

        should "include total_spend" do
          assert_equal 424242, @spending_data[:total_spend]
        end

        should "include company_count" do
          assert_equal 21, @spending_data[:company_count]
        end

        should "include largest_transactions" do
          assert_equal [@financial_transaction.id], @spending_data[:largest_transactions]
        end

        should "include largest_companies" do
          assert_equal [@company.id], @spending_data[:largest_companies]
        end

        should "include largest_charities" do
          assert_equal [@charity.id], @spending_data[:largest_charities]
        end
      end
    end
    
    context "when caching spending data" do
      setup do
        Council.stubs(:calculated_spending_data).returns({:total_spend => 1234, :transaction_count => 45})
        @cached_file_location = File.join(RAILS_ROOT, 'db', 'data', 'cache', 'council_spending')
      end
      
      teardown do
        File.delete(@cached_file_location) if File.exist?(@cached_file_location)
      end
      
      should "get calculated spending data" do
        Council.expects(:calculated_spending_data)
        Council.cache_spending_data
      end
      
      should "save calculated spending data as yaml in file" do
        Council.cache_spending_data
        YAML.load_file(@cached_file_location)
      end

      should "return file location" do
        assert_equal @cached_file_location, Council.cache_spending_data
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

    should "return self as council" do
      assert_equal @council, @council.council
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

    should 'return resource_uri' do
      assert_equal "http://#{DefaultDomain}/id/councils/#{@council.id}", @council.resource_uri
    end
    
    context "when saving" do
      should "normalise title" do
        @council.expects(:normalise_title)
        @council.save!
      end

      should "save normalised title" do
        @council.title = "Vale of White Horse District Council"
        @council.save!
        assert_equal "vale of white horse", @council.reload.normalised_title
      end
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
    
    context 'when returning fix_my_street_url' do
      should 'build url using snac id' do
        @council.snac_id = '00AB'
        assert_equal 'http://fixmystreet.com/reports/00AB', @council.fix_my_street_url
      end
      
      should 'return nil if snac_id blank' do
        assert_nil @council.fix_my_street_url
        @council.snac_id = ''
        assert_nil @council.fix_my_street_url
      end
      
    end
    
    context "when returning parsed status" do
      should "return true if it has members" do
        Factory(:member, :council => @council)
        assert @council.parsed?
      end

      should "return false if it has no members" do
        assert !@council.parsed?
      end
      
      should "return true if it responds to member_count and member_count is greater than 0" do
        @council.stubs(:member_count => "3")
        assert @council.parsed?
      end

      should "return true if it responds to member_count and member_count is 0" do
        @council.stubs(:member_count => "0")
        assert !@council.parsed?
      end

      should "not try to count members if it responds to member_count" do
        @council.stubs(:member_count)
        @council.expects(:members).never
        @council.parsed?
      end

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
    
    context "when returning open_data status" do
      should "return no_open_data by default" do
        assert_equal 'no_open_data', @council.open_data_status
      end
      
      should 'return semi_open_data if council has open data url and open_data_licence is nil' do
        @council.open_data_url = 'http://council.gov.uk/open'
        assert_equal 'semi_open_data', @council.open_data_status
      end
      
      should 'return open_data if council has open data url and open_data_licence is open' do
        @council.open_data_url = 'http://council.gov.uk/open'
        @council.open_data_licence = 'CCBY30'
        assert_equal 'open_data', @council.open_data_status
      end
      
      should 'return semi_open_data if council has open data url and open_data_licence is semi_open' do
        @council.open_data_url = 'http://council.gov.uk/open'
        @council.open_data_licence = 'CCBYNC30'
        assert_equal 'semi_open_data', @council.open_data_status
      end
    end

    context "when returning open_data licence name" do
      should "return nil by default" do
        assert_nil @council.open_data_licence_name
      end
      
      should 'return licence details associated with licence' do
        @council.open_data_licence = 'CCBY30'
        assert_equal 'Creative Commons By Attribution 3.0', @council.open_data_licence_name
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
        @council.twitter_account_name = "twitter_foo"
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

      should "include forthcoming meeting openlylocal_url" do
        assert_match %r(<meeting.+<openlylocal-url>#{@future_meeting.openlylocal_url}.+</meeting.+<recent-activity)m, @council.to_detailed_xml
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

      should "include status of member in recent activity" do
        assert_match %r(<twitter-account.+<name>twitter_foo)m, @council.to_detailed_xml
      end
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
    
    context "when updating_social_networking_info for Council class" do
      setup do
        dummy_response = { :twitter_account_name => "foo", :feed_url => "http://council.gov.uk/feed" }
        SocialNetworkingUtilities::Finder.stubs(:new).returns(stub(:process => dummy_response))
        Council.stubs(:all).returns([@council])
      end
      
      should "get all councils" do
        Council.expects(:all).returns([@council])
        Council.update_social_networking_info
      end
      
      should "updating_social_networking_info for councils" do
        @council.expects(:update_social_networking_info).returns({})
        Council.update_social_networking_info
      end
      
      should "not raise exception if problems getting data" do
        @council.expects(:update_social_networking_info).raises(StandardError, "OpenURI Error")
        assert_nothing_raised() { Council.update_social_networking_info }
      end
      
      should "email admin report" do
        AdminMailer.expects(:deliver_admin_alert!)
        Council.update_social_networking_info
      end
      
      should "include exceptions raised in email admin report" do
        @council.stubs(:update_social_networking_info).raises(StandardError, "OpenURI Error")
        Council.update_social_networking_info
        assert_sent_email do |email|
          email.body =~ /Exception raised.+#{@council.title}.+OpenURI Error/i
        end
      end
      
      context "and when emailing admin report" do
        setup do
          @council.expects(:update_social_networking_info).returns({:updates => 2})
          @error_message = "new twitter_account_name (foo) does not match old twitter_account_name (bar)"
          @council.errors.add_to_base(@error_message)
          Council.update_social_networking_info
        end
        
        should "have subject" do
          assert_sent_email do |email|
            email.subject =~ /Council Social Networking Info Report/i
          end
        end
        
        should "include number of errors in subject" do
          assert_sent_email do |email|
            email.subject =~ /1 errors/i
          end
        end
        
        should "include number of updates in subject" do
          assert_sent_email do |email|
            email.subject =~ /2 updates/i
          end
        end
        
        should "list council and errors in report" do
          assert_sent_email do |email|
            email.body =~ /#{@council.title}.+#{Regexp.escape(@error_message)}/m
          end
        end
        
      end
    end
    
    context "when updating_social_networking_info" do
      setup do
        dummy_response = { :twitter_account_name => "foo", :feed_url => "http://council.gov.uk/feed" }
        SocialNetworkingUtilities::Finder.stubs(:new).returns(stub(:process => dummy_response))
      end
      
      should "call SocialNetwork::Finder with council url" do
        SocialNetworkingUtilities::Finder.expects(:new).with(@council.url).returns(stub(:process => {}))
        @council.update_social_networking_info
      end
      
      should "update empty attributes with info returned from SocialNetwork::Finder" do
        @council.update_social_networking_info
        assert_equal "foo", @council.reload.twitter_account_name
        assert_equal "http://council.gov.uk/feed", @council.feed_url
      end
      
      should "not update existing attributes with info returned from SocialNetwork::Finder" do
        @council.update_attributes(:twitter_account_name => "bar", :feed_url => "http://council.gov.uk/old_feed")
        @council.update_social_networking_info
        assert_equal "bar", @council.reload.twitter_account_name
        assert_equal "http://council.gov.uk/old_feed", @council.feed_url
      end
      
      context "result of updating" do
        setup do
        end
        
        should "return hash of info" do
          assert_kind_of Hash, @council.update_social_networking_info
        end
        
        should "not count as errors entries where no result returned but existing info" do
          @council.update_attributes(:twitter_account_name => "bar")
          SocialNetworkingUtilities::Finder.stubs(:new).returns(stub(:process => {:feed_url => "http://council.gov.uk/feed"})) # no twitter_account_name
          @council.update_social_networking_info
          assert_no_match %r(twitter_account_name), @council.errors[:base]
        end
        
        should "not count as errors entries is same as existing info" do
          @council.update_attributes(:twitter_account_name => "foo")
          @council.update_social_networking_info
          assert_no_match %r(twitter_account_name), @council.errors[:base]
        end
        
        should "not count as errors entries is same as existing info but different case" do
          @council.update_attributes(:twitter_account_name => "Foo")
          @council.update_social_networking_info
          assert_no_match %r(twitter_account_name), @council.errors[:base]
        end
        
        should "add errors to council" do
          @council.update_attributes(:twitter_account_name => "bar")
          @council.update_social_networking_info
          assert_equal "new twitter_account_name (foo) does not match old twitter_account_name (bar)", @council.errors[:base]
        end
        
        should "list number of successful updates" do
          @council.update_attributes(:twitter_account_name => "bar")
          assert_equal 1, @council.update_social_networking_info[:updates]
        end
      end
    end
    
    context 'when updating election results' do
      setup do
        @ward_1 = Factory(:ward, :council => @council, :snac_id => '41UDGE')
        @dummy_response = {:results => 
          {'http://openelectiondata.org/id/election/41UD/2007-05-03' => 
            [{ :uri => 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03',
              :source => 'http://anytown.gov.uk/elections/poll/foo',
              :area => 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', 
              :date => '2007-05-03', 
              :electorate => '4409', 
              :ballots_issued => '1642', 
              :uncontested => nil, 
              :candidacies => [{:given_name => 'Margaret', 
                                :family_name => 'Stanhope',
                                :votes => '790',
                                :elected => 'true',
                                :party => 'http://openelectiondata.org/id/parties/25',
                                :independent => nil },
                               {:name => 'John Linnaeus Middleton', 
                                :votes => '342',
                                :elected => 'true',
                                :party => nil,
                                :independent => true }
                ] }]
              }
            }
        ElectionResultExtractor.stubs(:poll_results_for).returns(@dummy_response)
      end
      
      should 'use election_result_extractor to get results' do
        ElectionResultExtractor.expects(:poll_results_for).with(@council).returns(@dummy_response)
        @council.update_election_results
      end
      
      should 'create or update polls with the result' do
        Poll.expects(:from_open_election_data).with(@dummy_response[:results].values.first, anything) # only uses poll array, not election => poll hash
        @council.update_election_results
      end
      
      should 'submit self as council when creating or updating polls with the result' do
        Poll.expects(:from_open_election_data).with(anything, :council => @council)
        @council.update_election_results
      end
      
      should 'not create or update polls if no results' do
        ElectionResultExtractor.expects(:poll_results_for).returns({})
        Poll.expects(:from_open_election_data).never
        @council.update_election_results
      end
    end

    context "when notifying local hyperlocal sites" do
      setup do
        @dummy_tweeter = Tweeter.new('foo')
        @another_council = Factory(:another_council)
        @hyperlocal_site = Factory(:approved_hyperlocal_site, :twitter_account_name=>'foolocal', :council => @council)
        @another_hyperlocal_site = Factory(:approved_hyperlocal_site, :twitter_account_name=>'barlocal', :council => @council)
      end
      
      should "create tweet to each hyperlocal site with given message and hyperlocal twitter ids" do
        Tweeter.expects(:new).with('@foolocal Hello World', anything).returns(@dummy_tweeter)
        Tweeter.expects(:new).with('@barlocal Hello World', anything).returns(@dummy_tweeter)
        @council.notify_local_hyperlocal_sites('Hello World')
      end
      
      should "queue up tweets for delivery later" do
        Delayed::Job.expects(:enqueue).with(kind_of(Tweeter)).twice
        @council.notify_local_hyperlocal_sites('Hello World')
      end
      
      should "not send any tweets if no hyperlocal sites" do
        Tweeter.expects(:new).never
        Delayed::Job.expects(:enqueue).never
        @another_council.notify_local_hyperlocal_sites('Hello World')
      end
      
      should "not send tweets for hyperlocal sites without twitter account" do
        @no_twitter_hyperlocal_site = Factory(:approved_hyperlocal_site, :council => @council)
        Tweeter.expects(:new).twice.returns(@dummy_tweeter) # only twice
        @council.notify_local_hyperlocal_sites('Hello World')
      end
      
      should "pass options to Tweeter" do
        Tweeter.expects(:new).with(anything, :foo => 'bar').twice.returns(@dummy_tweeter)
        @council.notify_local_hyperlocal_sites('Hello World', :foo => 'bar')
      end
      
    end
  end
  
  private
  def mark_as_stale(rec)
    rec.class.record_timestamps = false
    rec.update_attributes(:created_at => 2.months.ago, :updated_at => 2.months.ago)
    rec.class.record_timestamps = true
  end
  
end
