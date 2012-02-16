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
  end
end
