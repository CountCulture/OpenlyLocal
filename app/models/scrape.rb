class Scrape < ActiveRecord::Base
  validates_presence_of :scraper_id
  belongs_to :scraper
  serialize :results
  serialize :scraping_errors
end
