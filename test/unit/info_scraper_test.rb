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
      assert_equal "info on Members from Member's url", @scraper.scraping_for
    end
    
    should "return include url it is if set" do
      @scraper.url = "http://foo.com/something"
      assert_equal "info on Members from <a href='http://foo.com/something'>http://foo.com/something</a>", @scraper.scraping_for
    end
    
    should "search result model for related_objects when none exist" do
      Member.expects(:find).with(:all, :conditions => {:council_id => @scraper.council_id}).returns("related_objects")
      assert_equal "related_objects", @scraper.related_objects
    end
    
    should "not search result model for related_objects when already exist" do
      @scraper.instance_variable_set(:@related_objects, "foo")
      Member.expects(:find).never
      assert_equal "foo", @scraper.related_objects
    end
    
    context "when processing" do
      
      should "not search for related_objects when passed as params" do
        Member.expects(:find).never
        @scraper.process(:objects => Member.new)
      end
      
      should "treat object passed as parameter as related objects" do
        obj = Member.new
        assert_equal [obj], @scraper.process(:objects => obj ).related_objects
      end
      
      should "search for related_objects when passed as params" do
        Member.expects(:find).returns([])
        @scraper.process
      end
      
      context "with single object" do
        setup do
          @scraper.stubs(:_data).returns("something")
          @parser = @scraper.parser
          @parser.stubs(:results).returns([{ :full_name => "Fred Flintstone", :url => "http://www.anytown.gov.uk/members/fred" }] )
          @dummy_related_object = Member.new(:url => "http://www.anytown.gov.uk/members/fred")
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
          assert_equal "Fred Flintstone", @dummy_related_object.full_name
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
          assert_equal "Member", results.first.base_object_klass
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
        
      end
      
      context "with collection of objects" do
        setup do
          @dummy_object_1, @dummy_object_2 = Factory(:member, :council => @scraper.council), Factory(:member, :council => @scraper.council)
          @dummy_collection = [@dummy_object_1, @dummy_object_2]
          @scraper.stubs(:_data).returns("something")
          @scraper.stubs(:related_objects).returns(@dummy_collection)
          @parser = @scraper.parser
          
          @parser.stubs(:results).returns([{ :full_name => "Fred Flintstone", 
                                             :url => "http://www.anytown.gov.uk/members/fred" }] 
                                          ).then.returns([{ :full_name => "Barney Rubble", 
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
          assert_equal "Fred Flintstone", @dummy_object_1.full_name
          assert_equal "Barney Rubble", @dummy_object_2.full_name
        end
      
        should "validate existing instance of result_class" do
          @dummy_object_1.expects(:valid?)
          @scraper.process
        end
      
        should "store scraped_object_result objects in results" do
          results = @scraper.process.results
          assert_equal 2, results.size
          assert_kind_of ScrapedObjectResult, results.first
          assert_equal "Member", results.last.base_object_klass
          assert_equal ["Bob", "Barney"], results.last.changes["first_name"]
        end
      
        should "not mark scraper as problematic" do
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
            Member.any_instance.expects(:attributes=).once
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
        
      end
    end
  end
  
end
