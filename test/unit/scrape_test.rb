require 'test_helper'

class ScrapeTest < ActiveSupport::TestCase
  
  context "the Scrape class" do
    should validate_presence_of :scraper_id

    should have_db_column :results
    should have_db_column :results_summary
    should have_db_column :scraping_errors
    should belong_to :scraper
    
    should 'serialize results' do
      results = {:foo => 'bar'}
      assert_equal results, Factory(:scrape, :results => results).reload.results
    end
    
    should 'serialize scraping_errors' do
      errors = {:foo => 'bar'}
      assert_equal errors, Factory(:scrape, :scraping_errors => errors ).reload.scraping_errors
    end
    
    context "when returning recent" do
      setup do
        @scraper = Factory(:scraper)
        @scrape_1 = Factory(:scrape, :scraper => @scraper)
        sleep 1
        @scrape_2 = Factory(:scrape, :scraper => @scraper)
        sleep 1
        @scrape_3 = Factory(:scrape, :scraper => @scraper)
        sleep 1
        @scrape_4 = Factory(:scrape, :scraper => @scraper)
        @recent = Scrape.recent.all
      end

      should "include most recent 3 scrapes" do
        assert_equal 3, @recent.size
      end
      
      should "order by created_at datetime" do
        assert_equal @scrape_4, @recent.first
        assert_equal @scrape_2, @recent.last
        assert !@recent.include?(@scrape_1)
      end
    end
    
  end
end
