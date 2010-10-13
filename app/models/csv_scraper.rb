class CsvScraper < Scraper
  
  def _data(target_url=nil)
    logger.debug { "Getting data from #{target_url}" }
    page_data = _http_get(target_url)
  rescue Exception => e
    error_message = "**Problem getting data from #{target_url}: #{e.inspect}\n #{e.backtrace}"
    logger.error { error_message }
    raise RequestError, error_message
  end
  
end