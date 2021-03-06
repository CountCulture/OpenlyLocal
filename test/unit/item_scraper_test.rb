require File.expand_path('../../test_helper', __FILE__)

class ItemScraperTest < ActiveSupport::TestCase
  
  context "The ItemScraper class" do
    
    should "be subclass of Scraper class" do
      assert_equal Scraper, ItemScraper.superclass
    end
  end

  context "an ItemScraper instance" do
    setup do
      @scraper = Factory(:item_scraper)
      @scraper.parser.update_attribute(:result_model, "TestScrapedModel")
    end

    should "return what it is scraping for" do
      assert_equal "TestScrapedModels from <a href='http://www.anytown.gov.uk/members'>http://www.anytown.gov.uk/members</a>", @scraper.scraping_for
    end
    
    context "with related model" do
      setup do
        @scraper.parser.update_attributes(:result_model => "TestChildModel", :related_model => "TestScrapedModel")
      end

      should "return related model" do
        assert_equal "TestScrapedModel", @scraper.related_model
      end

      should "get related objects from related model" do
        TestScrapedModel.expects(:find).with(:all, :conditions => {:council_id => @scraper.council_id}).returns("related_objects")

        assert_equal "related_objects", @scraper.related_objects
      end

      should "not search related model for related_objects when already exist" do
        @scraper.instance_variable_set(:@related_objects, "foo")
        TestScrapedModel.expects(:find).never
        assert_equal "foo", @scraper.related_objects
      end
    end
    
  
    context "when processing" do
      setup do
        @parser = @scraper.parser
        Parser.any_instance.stubs(:results).returns([{ :uid => 456 }, { :uid => 457 }] ).then.returns(nil) #second time around finds no results
        @scraper.stubs(:_data).returns("something")
      end
      
      context "item_scraper with url" do
      
        should "get data from url" do
          # This behaviour is inherited from parent Scraper class, so this is (poss unnecessary) sanity check
          @scraper.expects(:_data).with("http://www.anytown.gov.uk/members", anything)
          @scraper.process
        end
      
        should "pass self to associated parser" do
          @parser.expects(:process).with(anything, @scraper, anything).returns(stub_everything(:results => []))
          @scraper.process
        end
        
        should "not update last_scraped attribute if not saving results" do
          assert_nil @scraper.process.last_scraped
        end

        should "update last_scraped attribute if saving results" do
          @scraper.process(:save_results => true)
          assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
        end
        
        should "not update last_scraped if problem parsing" do
          @parser.update_attribute(:item_parser, "foo")
          @scraper.process(:save_results => true)
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

      context "and problem getting data" do
        context "in general" do
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

          should "not update last_scraped attribute when saving results" do
            assert_nil @scraper.process(:save_results => true).last_scraped
          end

          should "mark scraper as problematic" do
            @scraper.process
            assert @scraper.reload.problematic?
          end
        
          should "not clear set problematic flag" do
            @scraper.update_attribute(:problematic, true)
            @scraper.process
            assert @scraper.reload.problematic?
          end
        end

        context "and TimeoutError" do
          setup do
            @scraper.expects(:_data).raises(Scraper::TimeoutError, "Problem getting data from http://problem.url.com")
          end
          
          should "not mark scraper as problematic if TimeoutError" do
            @scraper.process
            assert !@scraper.reload.problematic?
          end
        end

        context "and WebsiteUnavailable" do
          setup do
            @scraper.expects(:_data).raises(Scraper::WebsiteUnavailable, "Problem: The darned website is unavailable")
          end
          
          should "not mark scraper as problematic if WebsiteUnavailable" do
            @scraper.process
            assert !@scraper.reload.problematic?
          end
        end
      end

      context "item_scraper with related_model" do
        setup do
          @scraper.parser.update_attributes(:result_model => "TestChildModel", :related_model => "TestScrapedModel")
          
          @dummy_object_1 = TestScrapedModel.create!(:title => "test model title 1", :url =>  "http://www.anytown.gov.uk/scraped_models/test_1", :uid => '42', :council => @scraper.council)
          @dummy_object_2 = TestScrapedModel.create!(:title => "test model title 2", :url =>  "http://www.anytown.gov.uk/scraped_models/test_2", :uid => '43', :council => @scraper.council)
          dummy_related_objects = [@dummy_object_1, @dummy_object_2]
          @scraper.stubs(:related_objects).returns(dummy_related_objects)
        end
        
        context "and url" do

          should "get data from scraper url" do
            @scraper.expects(:_data).with("http://www.anytown.gov.uk/members").twice # once for each related object
            @scraper.process
          end
        end
        
        context "and url with related object in it" do
          setup do
            @scraper.update_attribute(:url, 'http://www.anytown.gov.uk/meetings?ctte_id=#{uid}')
          end

          should "get data from url interpolated with related object" do
            @scraper.expects(:_data).with("http://www.anytown.gov.uk/meetings?ctte_id=#{@dummy_object_1.uid}")
            @scraper.expects(:_data).with("http://www.anytown.gov.uk/meetings?ctte_id=#{@dummy_object_2.uid}")
            @scraper.process
          end
          
          should "pass self to associated parser" do
            @parser.expects(:process).twice.with(anything, @scraper).returns(stub_everything(:results => []))
            @scraper.process
          end
          
          should "store all instances of scraped_object_result in results" do
            Parser.any_instance.stubs(:process).returns(stub_everything(:results => [{:date_held => 3.days.ago, :uid => 42}]))
            
            dummy_members = (1..3).collect{ |i|  TestChildModel.new(:date_held => i.days.ago, :committee_id => @dummy_object_1.id, :venue => "Venue #{i}") }
            TestChildModel.stubs(:build_or_update).returns([ScrapedObjectResult.new(dummy_members[0])]).then.returns([ScrapedObjectResult.new(dummy_members[1]), ScrapedObjectResult.new(dummy_members[2])])
            
            results = @scraper.process.results
            assert_equal 3, results.size
            assert_kind_of ScrapedObjectResult, results.first
            assert_match /new/, results.first.status
            assert_equal "TestChildModel", results.first.base_object_klass
            assert_equal "Venue 1", results.first.changes['venue'].last
          end          
          
          should "not update last_scraped attribute if not saving results" do
            assert_nil @scraper.process.last_scraped
          end

          should "update last_scraped attribute if saving results" do
            @scraper.process(:save_results => true)
            assert_in_delta(Time.now, @scraper.reload.last_scraped, 2)
          end

          should "not update last_scraped if problem parsing" do
            @parser.update_attribute(:item_parser, "foo")
            @scraper.process(:save_results => true)
            assert_nil @scraper.reload.last_scraped
          end
        end
        
        context "and no url" do
          setup do
            @scraper.update_attribute(:url, nil)
          end

          should "get data from each related_object's url" do
            @scraper.expects(:_data).with(@dummy_object_1.url)
            @scraper.expects(:_data).with(@dummy_object_2.url)
            @scraper.process
          end

          should "update result model with each result and related object details" do
            @scraper.expects(:update_with_results).with([{ :committee_id => @dummy_object_1.id, :uid => 456 }, { :committee_id => @dummy_object_1.id, :uid => 457 }], anything)
            @scraper.process
          end

          should "update result model passing on any options" do
            @scraper.expects(:update_with_results).with(anything, {:foo => "bar"})
            @scraper.process({:foo => "bar"})
          end
          
          should "not update last_scraped attribute if not saving results" do
            assert_nil @scraper.process.last_scraped
          end

          should "update last_scraped attribute if saving results" do
            @scraper.process(:save_results => true)
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

          context "and problem parsing" do
            setup do
              @parser.update_attribute(:item_parser, "foo")
              @scraper.process(:save_results => true)
            end
            
            should "not update last_scraped if problem parsing" do
              assert_nil @scraper.reload.last_scraped
            end

            should "mark scraper as problematic" do
              @scraper.process
              assert @scraper.reload.problematic?
            end
            
            should "not clear set problematic flag" do
              @scraper.update_attribute(:problematic, true)
              @scraper.process
              assert @scraper.reload.problematic?
            end

          end
          
        end
        
        context "and blank url" do
          setup do
            @scraper.update_attribute(:url, "")
          end

          should "get data from each related_object's url" do
            @scraper.expects(:_data).with(@dummy_object_1.url)
            @scraper.expects(:_data).with(@dummy_object_2.url)
            @scraper.process
          end

        end
        
        context "and problem getting data" do
          context "in general" do

            setup do
              @scraper.update_attribute(:url, nil)
              @scraper.stubs(:_data).with(@dummy_object_1.url).raises(Scraper::RequestError, "Problem getting data from http://problem.url.com: OpenURI::HTTPError: 404 Not Found")
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
          
            should "get data from other page" do
              @scraper.expects(:_data).with(@dummy_object_1.url)
              @scraper.process
            end

            should "mark scraper as problematic" do
              @scraper.process
              assert @scraper.reload.problematic?
            end
          
            should "not clear set problematic flag" do
              @scraper.update_attribute(:problematic, true)
              @scraper.process
              assert @scraper.reload.problematic?
            end
          end
          
          context "and TimeoutError" do
            setup do
              @scraper.update_attribute(:url, nil)
              @scraper.expects(:_data).with(@dummy_object_1.url).raises(Scraper::TimeoutError, "Problem (TimeoutError) getting data from http://problem.url.com")
            end
            
            should "not mark scraper as problematic" do
              @scraper.process
              assert !@scraper.reload.problematic?
            end
          end

          context "and WebsiteUnavailable" do
            setup do
              @scraper.update_attribute(:url, nil)
              @scraper.expects(:_data).with(@dummy_object_1.url).raises(Scraper::WebsiteUnavailable, "Problem: The darned website is unavailable")
            end

            should "not mark scraper as problematic if WebsiteUnavailable" do
              @scraper.process
              assert !@scraper.reload.problematic?
            end
          end
        end
      end
            
    end
  end
end
