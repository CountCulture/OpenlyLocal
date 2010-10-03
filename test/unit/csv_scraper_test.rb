require 'test_helper'

class ItemScraperTest < ActiveSupport::TestCase
  
  context "The CsvScraper class" do
    
    should "be subclass of Scraper class" do
      assert_equal Scraper, CsvScraper.superclass
    end
  end

  context "a CsvScraper instance" do
    setup do
      @scraper = Factory(:csv_scraper)
      @scraper.parser.update_attribute(:result_model, "TestScrapedModel")
    end
    
    context "when getting data" do

      should "get given url" do
        @scraper.expects(:_http_get).with('http://another.url', anything).returns("something")
        @scraper.send(:_data, 'http://another.url')
      end
      
      
      should "return data as string" do
        @scraper.stubs(:_http_get).returns("something")
        assert_equal "something", @scraper.send(:_data)
      end
            
      should "raise RequestError when problem getting page" do
        @scraper.expects(:_http_get).raises(OpenURI::HTTPError, "404 Not Found")
        assert_raise(Scraper::RequestError) {@scraper.send(:_data)}
      end
    end
    
    context "when processing" do
      setup do
        @csv_parser = Factory(:csv_parser)
      end
      
      context "in general" do
      # NB This isn't actually any different from superclass #process. THis just rests the linking with csv parser
        setup do
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
          @csv_parser.expects(:process).with("something", anything).returns(stub_everything)
          @scraper.process
        end

        should "pass self to associated parser" do
          @csv_parser.expects(:process).with(anything, @scraper).returns(stub_everything)
          @scraper.process
        end

        should "return self" do
          assert_equal @scraper, @scraper.process
        end
      end
      
      should "process csv data into instances of result model" do
        # This is sort of integration test
        @scraper.parser.update_attribute(:result_model, 'FinancialTransaction')
        @csv_rawdata = dummy_csv_data('supplier_payments')
        CsvScraper.any_instance.stubs(:_data).returns(@csv_rawdata)
        results = @scraper.process.results
        assert_equal 19, results.size
        assert_kind_of FinancialTransaction, results.first
      end
      
      context "and save_results requested" do
        setup do
          @scraper.parser.update_attribute(:result_model, 'FinancialTransaction')
          @csv_rawdata = dummy_csv_data('supplier_payments')
          CsvScraper.any_instance.stubs(:_data).returns(@csv_rawdata)
        end
        
        should "create new or update and save existing instance of result_class with parser results and scraper council" do
          dummy_scraped_obj = TestScrapedModel.new
          FinancialTransaction.expects(:build_or_update).with(anything, {:organisation => @scraper.council, :save_results => true}).returns([])
          @scraper.process(:save_results => true)
        end

        should "save processed csv data as instances of result model" do
          assert_difference "FinancialTransaction.count", 19 do
            results = @scraper.process(:save_results => true).results
          end
        end
        
        should "return saved instances of result model" do
          results = @scraper.process(:save_results => true).results
          assert_kind_of FinancialTransaction, results.first
        end
        
        should "use parsed information when creating instances of result model" do
          ft = @scraper.process(:save_results => true).results.first
          assert_equal "Idox Software Limited", ft.supplier_name
          assert_equal "2010-03-17",ft.date.to_s
          assert_equal 1000.0, ft.value
        end
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
  end
end