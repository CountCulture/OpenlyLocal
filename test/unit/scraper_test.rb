require 'test_helper'

#  TO DO: Sort out testing and behavious of #process method. At the 
# moment Scraper#process method is never called directly, only via 
# a super in a single case of ItemScraper. So tests are being 
# duplicated, as is code, and since we enver have an instance of the base
# Scraper model, prob shouldn't be testing it, rather should test a 
# basic scraper that inherits from it. 
class ScraperTest < ActiveSupport::TestCase
  subject { @scraper }  
  
  context "The Scraper class" do
    setup do
      @scraper = Factory.create(:scraper)
    end
    should belong_to :parser
    should belong_to :council
    should validate_presence_of :council_id
    # should_accept_nested_attributes_for :parser
    
    should "should_accept_nested_attributes_for parser" do
      assert Scraper.instance_methods.include?("parser_attributes=")
    end

    should "define ScraperError as child of StandardError" do
      assert_equal StandardError, Scraper::ScraperError.superclass
    end
    
    should "define RequestError as child of ScraperError" do
      assert_equal Scraper::ScraperError, Scraper::RequestError.superclass
    end
    
    should "define ParsingError as child of ScraperError" do
      assert_equal Scraper::ScraperError, Scraper::ParsingError.superclass
    end
    
    should "have stale named_scope" do
      expected_options = { :conditions => ["(type != 'CsvScraper') AND ((last_scraped IS NULL) OR (last_scraped < ?))", 7.days.ago], :order => "last_scraped" }
      actual_options = Scraper.stale.proxy_options
      assert_equal expected_options[:conditions].first, actual_options[:conditions].first
      assert_in_delta expected_options[:conditions].last, actual_options[:conditions].last, 2
      assert_equal expected_options[:order], actual_options[:order]
    end
    
    should "return stale scrapers" do
      # just checking...
      @scraper.update_attribute(:last_scraped, 6.days.ago)
      stale_scraper = Factory(:item_scraper, :last_scraped => 8.days.ago)
      never_used_scraper = Factory(:info_scraper)
      assert_equal [never_used_scraper, stale_scraper], Scraper.stale
    end
    
    should "not include CsvScrapers in stale scrapers" do
      csv_scraper = Factory(:csv_scraper, :last_scraped => 8.days.ago)
      assert !Scraper.stale.include?(csv_scraper)
    end
    
    should "have problematic named_scope" do
      expected_options = { :conditions => { :problematic => true } }
      actual_options = Scraper.problematic.proxy_options
      assert_equal expected_options, actual_options
    end
    
    should "have unproblematic named_scope" do
      expected_options = { :conditions => { :problematic => false } }
      actual_options = Scraper.unproblematic.proxy_options
      assert_equal expected_options, actual_options
    end
    
  end
  
  context "A Scraper instance" do
    setup do
      @scraper = Factory.create(:scraper)
      @council = @scraper.council
      @parser = @scraper.parser
    end
    
    should "return what it is scraping for" do
      parser = Factory(:parser, :result_model => 'TestScrapedModel')
      scraper = Scraper.new(:parser => parser, :url => 'http://www.anytown.gov.uk/members')
      assert_equal "TestScrapedModels from <a href='http://www.anytown.gov.uk/members'>http://www.anytown.gov.uk/members</a>", scraper.scraping_for
    end
    
    should "not save unless there is an associated parser" do
      s = Scraper.new(:council => @council)
      assert !s.save
      assert_equal "can't be blank", s.errors[:parser]
    end
    
    should "save if there is an associated parser set via parser_id" do
      # just checking...
      s = Scraper.new(:council => @council, :parser_id => @parser.id)
      assert s.save
    end
    
    should "be stale if last_scraped more than 1 week ago" do
      @scraper.update_attribute(:last_scraped, 8.days.ago)
      assert @scraper.stale?
    end
    
    should "not be stale if last_scraped less than 1 week ago" do
      @scraper.update_attribute(:last_scraped, 6.days.ago)
      assert !@scraper.stale?
    end
    
    should "be stale if last_scraped nil" do
      assert @scraper.stale?
    end
    
    should "not be problematic by default" do
      assert !@scraper.problematic?
    end
    
    context "when assigning parser attributes" do
      setup do
        @parser_attributes =  { :result_model => "Committee", 
                                :scraper_type => "InfoScraper",
                                :item_parser => "new code",
                                :attribute_parser_object => [{"attrib_name" => "baz", "parsing_code" => "baz1"}] }        
        @csv_parser_attributes = { :result_model => "Committee", 
                                   :scraper_type => "InfoScraper",
                                   :type => 'CsvParser', 
                                   :attribute_mapping_object => [{"attrib_name" => "foo", "column_name" => "FooName"}] }        
        @blank_scraper = Factory.build(:scraper, :council => @scraper.council, :parser => nil)
      end
      
      context "in general" do
        setup do
          @blank_scraper.parser_attributes = @parser_attributes
        end

        should 'initialise base parser by default' do
          assert_kind_of Parser, @blank_scraper.parser
        end

        should "initialize parser with given attributes" do
          assert_equal "Committee", @blank_scraper.parser.result_model
          assert_equal( {:baz => 'baz1'}, @blank_scraper.parser.attribute_parser)
        end
      end
      
      context "and CsvParser type specified" do
        setup do
          @blank_scraper.parser_attributes = @csv_parser_attributes
        end

        should 'intialize CsvParser' do
          assert_kind_of CsvParser, @blank_scraper.parser
        end
        
        should 'intialize with given attributes' do
          assert_equal( {:foo => "FooName"}, @blank_scraper.parser.attribute_mapping)
        end
      end
      
      context "and parser already exists" do
        setup do
          @scraper.parser_attributes = @parser_attributes
        end

        should 'update existing parser with given attributes' do
          assert_equal @parser, @scraper.parser
          assert_equal "new code", @scraper.parser.reload.item_parser
        end
      end
      
    end
    

    context "when returning status" do

      should "return 'stale' if stale" do
        assert_equal 'stale', @scraper.status
      end

      should "return 'problematic' if problematic" do
        @scraper.problematic = true
        @scraper.last_scraped = 6.days.ago
        assert_equal 'problematic', @scraper.status
      end
      
      should "return 'stale' and 'problematic' if stale and problematic" do
        @scraper.problematic = true
        assert_equal 'stale problematic', @scraper.status
      end
    end
        
    should "return sibling_scrapers" do
      sibling1 = Factory(:info_scraper, :council => @scraper.council)
      sibling2 = Factory(:scraper, :council => @scraper.council, :parser => Factory(:parser, :result_model => "Committee"))
      assert_equal [sibling1, sibling2], @scraper.sibling_scrapers
    end
    
    should "delegate result_model to parser" do
      @parser.expects(:result_model).returns("result_model")
      assert_equal "result_model", @scraper.result_model
      @scraper.parser = nil
      assert_nil @scraper.result_model
    end
    
    should "delegate related_model to parser" do
      @parser.expects(:related_model).returns("related_model")
      assert_equal "related_model", @scraper.related_model
      @scraper.parser = nil
      assert_nil @scraper.result_model
    end
    
    should "delegate portal_system to council" do
      @council.expects(:portal_system).returns("portal_system")
      assert_equal "portal_system", @scraper.portal_system
      @scraper.council = nil
      assert_nil @scraper.portal_system
    end
    
    should "delegate base_url to council" do
      @council.expects(:base_url).returns("http://some.council.com/democracy")
      assert_equal "http://some.council.com/democracy", @scraper.base_url
      @scraper.council = nil
      assert_nil @scraper.base_url
    end
    
    should "have results accessor" do
      @scraper.instance_variable_set(:@results, "foo")
      assert_equal "foo", @scraper.results
    end
    
    should "return empty array as results if not set" do
      assert_equal [], @scraper.results
    end
    
    should "set empty array as results if not set" do
      @scraper.results
      assert_equal [], @scraper.instance_variable_get(:@results)
    end
    
    should_not allow_mass_assignment_of :results

    should "have parsing_results accessor" do
      @scraper.instance_variable_set(:@parsing_results, "foo")
      assert_equal "foo", @scraper.parsing_results
    end
    
    should "have related_objects accessor" do
      @scraper.instance_variable_set(:@related_objects, "foo")
      assert_equal "foo", @scraper.related_objects
    end
    
    should "build title from council short_name result class and scraper type" do
      @scraper.council.name = "Anytown Council"
      assert_equal "TestScrapedModel Item scraper for Anytown", @scraper.title
    end
    
    should "build title from result class and scraper type when no council" do
      @scraper.council = nil
      assert_equal "TestScrapedModel Item scraper", @scraper.title
    end
    
    should "return errors in parser as parsing errors" do
      @parser.errors.add_to_base("some error")
      assert_equal "some error", @scraper.parsing_errors[:base]
    end
    
    should "update last_scraped attribute without changing updated_at timestamp" do
      ItemScraper.record_timestamps = false # update timestamp without triggering callbacks
      @scraper.update_attributes(:updated_at => 2.days.ago) #... though thought from Rails 2.3 you could do this turning off timestamps
      ItemScraper.record_timestamps = true
      @scraper.send(:update_last_scraped)
      assert_in_delta 2.days.ago, @scraper.reload.updated_at, 2 # check timestamp hasn't changed...
      assert_in_delta Time.now, @scraper.last_scraped, 2 #...but last_scraped has
    end
    
    should "mark as problematic without changing updated_at timestamp" do
      ItemScraper.record_timestamps = false # update timestamp without triggering callbacks
      @scraper.update_attributes(:updated_at => 2.days.ago) #... though thought from Rails 2.3 you could do this without turning off timestamps
      ItemScraper.record_timestamps = true
      @scraper.send(:mark_as_problematic)
      assert_in_delta 2.days.ago, @scraper.reload.updated_at, 2 # check timestamp hasn't changed...
      assert @scraper.problematic?
    end
    
    should "mark as unproblematic without changing updated_at timestamp" do
      ItemScraper.record_timestamps = false # update timestamp without triggering callbacks
      @scraper.update_attributes(:updated_at => 2.days.ago, :problematic => true) #... though thought from Rails 2.3 you could do this without turning off timestamps
      ItemScraper.record_timestamps = true
      @scraper.send(:mark_as_unproblematic)
      assert_in_delta 2.days.ago, @scraper.reload.updated_at, 2 # check timestamp hasn't changed...
      assert !@scraper.problematic?
    end
    
    context "when calculating results_summary" do
      setup do
        @basic_sor = stub(:status => "unchanged")
        @error_sor = stub(:status => "errors unchanged")
        @changed_sor = stub(:status => "changed")
        @new_sor = stub(:status => "new changed")
      end

      should "return nil when no results" do
        assert_nil Scraper.new.results_summary
      end
      
      should "hash of changes and error" do
        @scraper.instance_variable_set :@results, [@error_sor]*3 + [@basic_sor]*5 + [@changed_sor]*2 + [@new_sor]
        assert_equal "1 new records, 3 errors, 2 changes", @scraper.results_summary
      end
      
      should "return ignore keys with zero values" do
        @scraper.instance_variable_set :@results, [@basic_sor]*5 + [@changed_sor]*2 + [@new_sor]
        assert_equal "1 new records, 2 changes", @scraper.results_summary
      end
      
      should "return 'No changes' if results but no changes, errors or new records" do
        @scraper.instance_variable_set :@results, [@basic_sor]*5
        assert_equal "No changes", @scraper.results_summary
      end
      
    end
    
    
    context "if scraper has url attribute" do
      setup do
        @scraper.url = 'http://www.anytown.gov.uk/members/bob'
      end
      
      should "return url attribute as url" do
        assert_equal 'http://www.anytown.gov.uk/members/bob', @scraper.url
      end
      
      should "ignore base_url and parser path when returning url" do
        @scraper.parser.expects(:path).never
        @scraper.expects(:base_url).never
        assert_equal 'http://www.anytown.gov.uk/members/bob', @scraper.url
      end
    end
    
    context "if url attribute is nil" do
      setup do
        @scraper.url = nil
      end
      
      should "use computed_url for url" do
        @scraper.expects(:computed_url).returns("http://council.gov.uk/computed_url/")
        assert_equal "http://council.gov.uk/computed_url/", @scraper.url
      end
    end
    
    context "if url attribute is blank" do
      setup do
        @scraper.url = ""
      end
      
      should "use computed_url for url" do
        @scraper.expects(:computed_url).returns("http://council.gov.uk/computed_url/")
        assert_equal "http://council.gov.uk/computed_url/", @scraper.url
      end
    end
    
    context "for computed url" do

      should "combine base_url and parser path" do
        @scraper.stubs(:base_url).returns("http://council.gov.uk/democracy/")
        @scraper.parser.stubs(:path).returns("path/to/councillors")
        assert_equal 'http://council.gov.uk/democracy/path/to/councillors', @scraper.computed_url
      end
      
      should "return nil if base_url is nil" do
        @scraper.stubs(:base_url) # => nil
        @scraper.parser.stubs(:path).returns("path/to/councillors")
        assert_nil @scraper.computed_url 
      end
      
      should "return nil if parser path is nil" do
        @scraper.stubs(:base_url).returns("http://council.gov.uk/democracy/")
        @scraper.parser.stubs(:path) # => nil
        assert_nil @scraper.computed_url
      end
    end
        
    context "that belongs to council with portal system" do
      setup do
        @portal_system = Factory(:portal_system, :name => "Big Portal System")
        @portal_system.parsers << @parser = Factory(:another_parser)
        @council.portal_system = @portal_system
      end

      should "return council's portal system" do
        assert_equal @portal_system, @scraper.portal_system
      end
      
      should "return portal system's parsers as possible parsers" do
        assert_equal [@parser], @scraper.possible_parsers
      end
    end
    
    context "has portal_parser? method which" do

      should "return true for if parser has associated portal system" do
        @scraper.parser.portal_system = Factory(:portal_system)
        assert @scraper.portal_parser?
      end
      
      should "return false if parser does not have associated portal system" do
        assert !@scraper.portal_parser?
      end
      
      should "return false if no parser" do
        assert !Scraper.new.portal_parser?
      end
    end
    
    context "when getting data" do
    
      should "get given url" do
        @scraper.expects(:_http_get).with('http://another.url', anything).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      should "pass scraper referrer if set" do
        @scraper.referrer_url = "http://referrer.com"
        @scraper.expects(:_http_get).with(anything, has_entry("Referer" => "http://referrer.com")).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      should "pass target url as referrer if referrer is set but not url" do
        @scraper.referrer_url = "foo"
        @scraper.expects(:_http_get).with(anything, has_entry("Referer" => "http://another.url")).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      should "pass dummy user agent" do
        @scraper.expects(:_http_get).with(anything, has_entry("User-Agent" => "Mozilla/4.0 (OpenlyLocal.com)")).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      should "get cookie from cookie_url if given" do
        @scraper.cookie_url = "http://cookie.com"
        @scraper.expects(:_http_get).with(anything, has_entry(:cookie_url => "http://cookie.com")).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      should "return data as Hpricot Doc" do
        @scraper.stubs(:_http_get).returns("something")
        assert_kind_of Hpricot::Doc, @scraper.send(:_data)
      end
      
      should "raise ParsingError when problem processing page with Hpricot" do
        Hpricot.expects(:parse).raises
        assert_raise(Scraper::ParsingError) {@scraper.send(:_data)}
      end
      
      should "raise RequestError when problem getting page" do
        @scraper.expects(:_http_get).raises(OpenURI::HTTPError, "404 Not Found")
        assert_raise(Scraper::RequestError) {@scraper.send(:_data)}
      end
    end
        
    context "when processing" do
      setup do
        @parser = @scraper.parser
        @scraper.stubs(:_data).returns("something")
      end

      context "in general" do
        setup do
          Parser.any_instance.stubs(:results).returns([{ :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }] )
        end

        should "get data from url" do
          @scraper.url = 'http://www.anytown.gov.uk/members/bob'
          @scraper.expects(:_data).with("http://www.anytown.gov.uk/members/bob")
          @scraper.process
        end

        should "pass data to associated parser" do
          @parser.expects(:process).with("something", anything, anything).returns(stub_everything)
          @scraper.process
        end

        should "pass self to associated parser" do
          @parser.expects(:process).with(anything, @scraper, anything).returns(stub_everything)
          @scraper.process
        end

        should "return self" do
          assert_equal @scraper, @scraper.process
        end

        should "build new or update existing instance of result_class with parser results and scraper council" do
          dummy_scraped_obj = TestScrapedModel.new

          TestScrapedModel.expects(:build_or_update).with([{:title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred"}], {:organisation => @council }).returns([dummy_scraped_obj])
          dummy_scraped_obj.expects(:save).never
          @scraper.process
        end

        should "validate instances of result_class" do
          TestScrapedModel.any_instance.expects(:valid?)
          @scraper.process
        end

        should "store instances of scraped_object_result in results" do
          dummy_scraped_obj = TestScrapedModel.new(:title => "Fred Flintstone")
          TestScrapedModel.stubs(:build_or_update).returns([ScrapedObjectResult.new(dummy_scraped_obj)])
          results = @scraper.process.results
          assert_kind_of ScrapedObjectResult, results.first
          assert_match /new/, results.first.status
          assert_equal "TestScrapedModel", results.first.base_object_klass
          assert_equal "Fred Flintstone", results.first.title
        end

        should "not update last_scraped attribute" do
          @scraper.process
          assert_nil @scraper.reload.last_scraped
        end

        should "not mark scraper as problematic" do
          @scraper.process
          assert !@scraper.reload.problematic?
        end

        should "clear set problematic flag if no problems" do
          @scraper.update_attribute(:problematic, true)
          @scraper.process
          assert !@scraper.reload.problematic?
        end
      end
      
      context "and problem parsing" do
        setup do
          @parser.update_attribute(:item_parser, "foo")
        end

        should "not build or update instance of result_class if no results" do
          TestScrapedModel.expects(:build_or_update).never
          @scraper.process
        end
        
        should "mark scraper as problematic" do
          @scraper.process
          assert @scraper.reload.problematic?
        end
        
        should "not clear set problematic flag " do
          @scraper.update_attribute(:problematic, true)
          @scraper.process
          assert @scraper.reload.problematic?
        end

      end
      
      context "and problem getting data" do
        
        setup do
          @scraper.expects(:_data).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found")
        end
        
        should "not raise exception" do
          assert_nothing_raised(Exception) { @scraper.process }
        end
        
        should "store error in scraper" do
          @scraper.process
          assert_equal "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found", @scraper.errors[:base]
        end
        
        should "return self" do
          assert_equal @scraper, @scraper.process
        end
      
        should "mark as problematic when problem getting page" do
          @scraper.process
          assert @scraper.reload.problematic?
        end
      end

      context "and saving results" do
        setup do
          Parser.any_instance.stubs(:results).returns([{ :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }] )
        end

        should "return self" do
          assert_equal @scraper, @scraper.process(:save_results => true)
        end

        should "create new or update and save existing instance of result_class with parser results and scraper council" do
          dummy_scraped_obj = TestScrapedModel.new
          TestScrapedModel.expects(:build_or_update).with([{:title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred"}], {:organisation => @council, :save_results => true}).returns([ScrapedObjectResult.new(dummy_scraped_obj)])
          @scraper.process(:save_results => true)
        end

        # should "save record using save_without_losing_dirty" do
        #   dummy_scraped_obj = Member.new
        #   Member.stubs(:build_or_update).returns(dummy_scraped_obj)
        #   dummy_scraped_obj.expects(:save_without_losing_dirty)
        #   
        #   @scraper.process(:save_results => true)
        # end

        should "store instances of result class in results" do
          dummy_scraped_obj = TestScrapedModel.new(:title => "Fred Flintstone")
          TestScrapedModel.stubs(:build_or_update).returns([ScrapedObjectResult.new(dummy_scraped_obj)])
          results = @scraper.process(:save_results => true).results
          
          assert_kind_of ScrapedObjectResult, results.first
          assert_match /new/, results.first.status
          assert_equal "TestScrapedModel", results.first.base_object_klass
          assert_equal "Fred Flintstone", results.first.title
        end
        
        should "update last_scraped attribute" do
          @scraper.process(:save_results => true)
          assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
        end
        
        should "not update last_scraped result attribute when problem getting data" do
          @scraper.expects(:_data).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found")
          @scraper.process(:save_results => true)
          assert_nil @scraper.reload.last_scraped
        end
        
        should "not update last_scraped result attribute when problem parsing" do
          @parser.update_attribute(:item_parser, "foo")
          @scraper.process(:save_results => true)
          assert_nil @scraper.reload.last_scraped
        end
      end

    end
    
    context "when processing with csv_parser" do
      setup do
        @csv_parser = Factory(:csv_parser)
        @scraper.update_attribute(:parser, @csv_parser)
        Parser.any_instance.stubs(:results).returns([{ :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }] )
        @scraper.stubs(:_data).returns("something")
      end
      
      should "get data from url" do
        @scraper.url = 'http://www.anytown.gov.uk/members/bob'
        @scraper.expects(:_data).with("http://www.anytown.gov.uk/members/bob")
        @scraper.process
      end
      
      should "pass data to associated parser" do
        @csv_parser.expects(:process).with("something", anything, anything).returns(stub_everything)
        @scraper.process
      end

      should "pass self to associated parser" do
        @csv_parser.expects(:process).with(anything, @scraper, anything).returns(stub_everything)
        @scraper.process
      end

      should "pass self to associated parser with save_results flag if true" do
        @csv_parser.expects(:process).with(anything, @scraper, :save_results => true).returns(stub_everything)
        @scraper.process(:save_results => true)
      end

      should "return self" do
        assert_equal @scraper, @scraper.process
      end
      
      context "and problem parsing" do
        setup do
          FasterCSV.stubs(:new).raises
          # @csv_parser.update_attribute(:attribute_mapping, {:fo})
        end

        should "not build or update instance of result_class if no results" do
          TestScrapedModel.expects(:build_or_update).never
          @scraper.process
        end
        
        should "mark scraper as problematic" do
          @scraper.process
          assert @scraper.reload.problematic?
        end
        
        should "not clear set problematic flag " do
          @scraper.update_attribute(:problematic, true)
          @scraper.process
          assert @scraper.reload.problematic?
        end

      end
      
    end

    context "when running perform" do
      setup do
        @scraper.stubs(:process).returns(@scraper)
      end

      should "should process scraping, saving results" do
        @scraper.expects(:process).with(:save_results => true)
        @scraper.perform
      end
      
      should "email results" do
        @scraper.perform
        assert_sent_email do |email|
          email.subject =~ /Scraping Report/ && email.body =~ /Scraping Results/
        end
      end
    end
    
    context "when evaluating target_url_for object" do
      setup do
        @obj = stub(:url => "http://foo.com", :uid => 42)
      end

      should "return object's url by default" do
        assert_equal "http://foo.com", @scraper.send(:target_url_for, @obj)
      end
      
      should "return scraper url if set" do
        @scraper.url = "http://bar.com"
        assert_equal "http://bar.com", @scraper.send(:target_url_for, @obj)
      end
      
      should "return scraper url interpolated with object's uid" do
        @scraper.url = 'http://bar.com/committee_id=#{uid}&foo=bar'
        assert_equal "http://bar.com/committee_id=42&foo=bar", @scraper.send(:target_url_for, @obj)
      end
    end
    
  end
  
  private
  def new_scraper(options={})
    Scraper.new(options)
  end
end
