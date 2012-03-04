require 'test_helper'


class InfoScraperTest < ActiveSupport::TestCase
  
  context "The InfoScraper class" do
    setup do
      @scraper = InfoScraper.new()
    end
    
    should "not validate presence of :url" do
      @scraper.valid? # trigger validation
      assert_nil @scraper.errors[:url]
    end
    
    should "be subclass of Scraper class" do
      assert_equal Scraper, InfoScraper.superclass
    end
  end
  
  context "an InfoScraper instance" do
    setup do
      @scraper = Factory.create(:info_scraper)
    end
    
    should "return what it is scraping for" do
      assert_equal "info on TestScrapedModels from TestScrapedModel's url", @scraper.scraping_for
    end
    
    should "return include url it is if set" do
      @scraper.url = "http://foo.com/something"
      assert_equal "info on TestScrapedModels from <a href='http://foo.com/something'>http://foo.com/something</a>", @scraper.scraping_for
    end
    
    context "when getting related_objects" do
      context "and related_objects instance variable set" do
        setup do
          @scraper.instance_variable_set(:@related_objects, "foo")
        end
    
        should "not search result model for related_objects when already exist" do
          TestScrapedModel.expects(:find).never
          assert_equal "foo", @scraper.related_objects
        end
      end

      should "search result model for related_objects when none exist" do
        stale_scope = mock('stale_scope')
        stale_scope.expects(:find).with(:all, :conditions => {:council_id => @scraper.council_id}).returns("related_objects")
        TestScrapedModel.expects(:stale).returns(stale_scope)
        assert_equal "related_objects", @scraper.related_objects
      end
      
      context "and info_scraper parser has bitwise_flag as attribute value" do
        setup do
          @scraper.parser.attribute_parser = @scraper.parser.attribute_parser.merge(:bitwise_flag => '4')
        end
        
        should "filter by objects where bitwise_flag value not set for given bit" do
          stale_scope = mock('stale_scope')
          stale_scope.expects(:find).with(:all, :conditions => ["council_id = ? AND bitwise_flag & ? = 0", @scraper.council_id, @scraper.parser.bitwise_flag])
          TestScrapedModel.expects(:stale).returns(stale_scope)
          @scraper.related_objects
        end
      end
      
    end
    
    context "when processing" do
      
      should "not search for related_objects when passed as params" do
        TestScrapedModel.expects(:find).never
        @scraper.process(:objects => TestScrapedModel.new)
      end
      
      should "treat object passed as parameter as related objects" do
        obj = TestScrapedModel.new
        assert_equal [obj], @scraper.process(:objects => obj ).related_objects
      end
      
      should "search for related_objects when passed as params" do
        TestScrapedModel.expects(:find).returns([]).at_least_once
        @scraper.process
      end
      
      context "with single object" do
        setup do
          @scraper.stubs(:_data).returns("something")
          @parser = @scraper.parser
          Parser.any_instance.stubs(:results).returns([{ :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }] )
          @dummy_related_object = TestScrapedModel.new(:url => "http://www.anytown.gov.uk/members/fred")
        end

        should "by default get data from object's url" do
          @scraper.expects(:_data).with("http://www.anytown.gov.uk/members/fred")
          @scraper.process(:objects => @dummy_related_object)
        end

        should "get data from url if set" do
          @scraper.update_attribute(:url, "http://some.other.url")
          @scraper.expects(:_data).with("http://some.other.url")
          @scraper.process(:objects => @dummy_related_object)
        end

        should "save in related_objects" do
          @scraper.process(:objects => @dummy_related_object)
          assert_equal [@dummy_related_object], @scraper.related_objects
        end

        should "return self" do
          assert_equal @scraper, @scraper.process(:objects => @dummy_related_object)
        end

        should "parse info returned from url" do
          @parser.expects(:process).with("something", anything).returns(stub_everything(:results => []))
          @scraper.process(:objects => @dummy_related_object)
        end
        
        should "pass self to associated parser" do
          @parser.expects(:process).with(anything, @scraper).returns(stub_everything(:results => []))
          @scraper.process(:objects => @dummy_related_object)
        end

        should "update existing instance of result_class" do
          @scraper.process(:objects => @dummy_related_object)
          assert_equal "Fred Flintstone", @dummy_related_object.title
        end
        
        should "clean up unknown attributes" do
          @dummy_related_object.expects(:clean_up_raw_attributes).with( :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred")
          @scraper.process(:objects => @dummy_related_object)
        end
        
        should "validate existing instance of result_class" do
          @scraper.process(:objects => @dummy_related_object)
          assert @dummy_related_object.errors[:uid]
        end
        
        should "not try to save existing instance of result_class" do
          @dummy_related_object.expects(:save).never
          @scraper.process(:objects => @dummy_related_object)
        end
        
        should "try to save existing instance of result_class" do
          @dummy_related_object.expects(:save)
          @scraper.process(:save_results => true, :objects => @dummy_related_object)
        end
        
        should "store scraped_object_result in results" do
          results = @scraper.process(:objects => @dummy_related_object).results
          assert_kind_of ScrapedObjectResult, results.first
          assert_equal "TestScrapedModel", results.first.base_object_klass
          assert_equal @dummy_related_object.url, results.first.url
        end
        
        should "not update last_scraped attribute if not saving results" do
          assert_nil @scraper.process(:objects => @dummy_related_object).last_scraped
        end
        
        should "update last_scraped attribute when saving results" do
          @scraper.process(:save_results => true, :objects => @dummy_related_object)
          assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
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
        
        context "and object has retrieved_at attribute" do
          setup do
            @dummy_object_with_retrieved_at = TestScrapedModelWithRetrievedAt.create!(:uid => '1234', :url => "http://www.anytown.gov.uk/members/fred", :council => @council)
            results = [{ :url => "http://new.url" }]
            Parser.any_instance.expects(:process).returns(stub_everything(:results => results))
          end

          should "update retrieved_at" do
            @scraper.process(:save_results => true, :objects => @dummy_object_with_retrieved_at).results
            assert_in_delta Time.now, @dummy_object_with_retrieved_at.reload.retrieved_at, 2
          end
        end

      end
      
      context "with collection of objects" do
        setup do
          @dummy_object_1 = TestScrapedModel.create!(:title => "test model title 1", :url =>  "http://www.anytown.gov.uk/scraped_models/test_1", :uid => '42', :council => @scraper.council)
          @dummy_object_2 = TestScrapedModel.create!(:title => "test model title 2", :url =>  "http://www.anytown.gov.uk/scraped_models/test_2", :uid => '43', :council => @scraper.council)
          @dummy_collection = [@dummy_object_1, @dummy_object_2]
          @scraper.stubs(:_data).returns("something")
          @scraper.stubs(:related_objects).returns(@dummy_collection)
          @parser = @scraper.parser
          
          Parser.any_instance.stubs(:results).returns([{ :title => "Fred Flintstone", 
                                             :url => "http://www.anytown.gov.uk/members/fred" }] 
                                          ).then.returns([{ :title => "Barney Rubble", 
                                                           :url => "http://www.anytown.gov.uk/members/barney" }])
        end
      
        should "get data from objects' urls" do
          @scraper.expects(:_data).with(@dummy_object_1.url).then.with(@dummy_object_2.url)
          @scraper.process
        end

        should "parse info returned from url" do
          @parser.expects(:process).with("something", anything).twice.returns(stub_everything(:results => []))
          @scraper.process
        end
        
        should "pass self to associated parser" do
          @parser.expects(:process).with(anything, @scraper).twice.returns(stub_everything(:results => []))
          @scraper.process
        end

        should "return self" do
          assert_equal @scraper, @scraper.process(:objects => @dummy_collection)
        end
      
        should "update collection objects" do
          @scraper.process
          assert_equal "Fred Flintstone", @dummy_object_1.title
          assert_equal "Barney Rubble", @dummy_object_2.title
        end
      
        should "validate existing instance of result_class" do
          @dummy_object_1.expects(:valid?)
          @scraper.process
        end
      
        should "store scraped_object_result objects in results" do
          results = @scraper.process.results
          assert_equal 2, results.size
          assert_kind_of ScrapedObjectResult, results.first
          assert_equal "TestScrapedModel", results.last.base_object_klass
          assert_equal ["test model title 2", "Barney Rubble"], results.last.changes["title"]
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

        should "not update last_scraped attribute when not saving" do
          @scraper.process
          assert_nil @scraper.reload.last_scraped
        end
        
        should "update last_scraped attribute when saving" do
          @scraper.process(:save_results => true)
          assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
        end
        
        context "and non-ScraperError occurs" do
          setup do
            @parser.update_attribute(:attribute_parser, {:foobar => "\"bar\""})
            Parser.any_instance.expects(:results).twice.returns([{ :title => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }]).then.raises(ActiveRecord::UnknownAttributeError, "unknown attribute foo")
          end

          should "catch exception" do
            assert_nothing_raised(Exception) { @scraper.process }
          end
          
          should "add details to scraper errors" do
            @scraper.process
            assert_match /unknown attribute foo/m, @scraper.errors[:base]
          end
          
          should "return self" do
            assert_equal @scraper, @scraper.process
          end
          
          should "mark scraper as problematic if saving results" do
            @scraper.process(:save_results => true)
            assert @scraper.reload.problematic?
          end
          
          should "not update last_scraped if saving results" do
            @scraper.process
            assert_nil @scraper.last_scraped
          end
          
        end
        
        context "and problem getting data on one of the objects" do
          setup do
            @scraper.expects(:_data).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found").then.returns("something")
          end

          should "not raise exception" do
            assert_nothing_raised(Exception) { @scraper.process }
          end

          should "store error in result object corresponding to initial object with problem" do
            @scraper.process
            assert_equal "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found", @scraper.results.first.errors[:base]
            assert_nil @scraper.results.last.errors[:base]
          end

          should "not add error to scraper" do
            @scraper.process
            assert_nil @scraper.errors[:base]
          end

          should "not try to validate object with problem" do
            # Poss change this test to test for saving when save results is true
            @dummy_collection.first.expects(:valid?).never
            @dummy_collection.last.expects(:valid?)
            @scraper.process
          end

          should "not build or update instance of result_class if no results for that instance" do
            TestScrapedModel.any_instance.expects(:attributes=).once
            @scraper.process
          end
          
          should "return self" do
            assert_equal @scraper, @scraper.process
          end

          should "update last_scraped attribute when saving" do
            @scraper.process(:save_results => true)
            assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
          end
          
          should "not mark scraper as problematic" do
            @scraper.process(:save_results => true)
            assert !@scraper.reload.problematic?
          end
        end

        context "and problem getting data on all of the objects" do
          setup do
            @scraper.expects(:_data).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found").twice
          end

          should "not raise exception" do
            assert_nothing_raised(Exception) { @scraper.process }
          end

          should "store error in result objects" do
            @scraper.process
            assert_equal "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found", @scraper.results.first.errors[:base]
            assert_equal "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found", @scraper.results.last.errors[:base]
          end

          should "not try to validate object with problem" do
            # Poss change this test to test for saving when save results is true
            @dummy_collection.first.expects(:valid?).never
            @dummy_collection.last.expects(:valid?).never
            @scraper.process
          end

          should "return self" do
            assert_equal @scraper, @scraper.process
          end

          should "not error to scraper" do
            @scraper.process
            assert_match /Problem on all items/, @scraper.errors[:base]
          end

          should "not update last_scraped attribute when saving" do
            @scraper.process(:save_results => true)
            assert_nil @scraper.reload.last_scraped
          end
          
          should "mark scraper as problematic when saving" do
            @scraper.process(:save_results => true)
            assert @scraper.reload.problematic?
          end
          
          should "mark scraper as problematic when not saving" do
            @scraper.process
            assert !@scraper.reload.problematic?
          end
        end
        
        context "and problem parsing data on one of the objects" do
          setup do
            @parser.update_attribute(:item_parser, "item.upcase")
            @scraper.expects(:_data).twice.returns(42).then.returns("something")
          end
          
          should "add parsing problem to relevant result object" do
            @scraper.process
            assert_nil @scraper.results.last.errors[:base]
            assert_match /Exception raised parsing items/, @scraper.results.first.errors[:base]
          end
          
          should "update last_scraped attribute when saving" do
            @scraper.process(:save_results => true)
            assert_in_delta Time.now, @scraper.reload.last_scraped, 2
          end

          should "not mark scraper as problematic when saving" do
            @scraper.process(:save_results => true)
            assert !@scraper.reload.problematic?
          end
        end
        
        context "and no objects to get data for" do
          # regression test. Sometimes we may have no stale objects
          setup do
            @scraper.stubs(:related_objects).returns([])
          end

          should "not mark as problematic" do
            @scraper.process(:save_results => true)
            assert !@scraper.reload.problematic?
          end
          
          should "not add error to scraper" do
            @scraper.process
            assert_nil @scraper.errors[:base]
          end

        end
      end
    end
  end
  
end
