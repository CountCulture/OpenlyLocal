class ScrapersController < ApplicationController
  before_filter :authenticate
  before_filter :find_scraper, :except => [:index, :new, :create]
  skip_before_filter :share_this
  newrelic_ignore
  
  def index
    @councils_with_scrapers, @councils_without_scrapers = Council.find(:all, :include => [{:scrapers => [:parser, :council]}, :portal_system], :order => "name").partition{ |c| !c.scrapers.empty? }
    @title = "All scrapers"
  end
  
  def show
    @title = @scraper.title
    @parser = @scraper.parser
  end
  
  def new
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    @council = Council.find(params[:council_id]) if params[:council_id]
    @scraper = params[:type].constantize.new(:council_id => params[:council_id])
    parser_type = @scraper.is_a?(CsvScraper) ? 'CsvParser' : 'Parser'
    parser = 
      case 
      when params[:parser_id]
        Parser.find(params[:parser_id])
      when @council&&@council.portal_system_id
        Parser.find_by_portal_system_id_and_result_model_and_scraper_type(@council.portal_system_id, params[:result_model], params[:type])
      else
        nil
      end
    @scraper.parser = parser || parser_type.constantize.new( :result_model => params[:result_model], :scraper_type => params[:type])
  end
  
  def create
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    @scraper = params[:type].constantize.new(params[:scraper])
    @scraper.save!
    flash[:notice] = "Successfully created scraper"
    redirect_to scraper_url(@scraper)
  end
  
  def edit
  end
  
  def update
    @scraper.update_attributes(params[:scraper])
    flash[:notice] = "Successfully updated scraper"
    redirect_to scraper_url(@scraper)
  end
  
  def destroy
    @scraper.destroy
    flash[:notice] = "Successfully destroyed scraper"
    redirect_to scrapers_url(:anchor => "council_#{@scraper.council_id}")
  end
  
  def scrape
    if params[:dry_run]
      @results = @scraper.process.results
      @results_summary = @scraper.results_summary
    elsif params[:process] == "immediately"
      @results = @scraper.process(:save_results => true).results
      @results_summary = @scraper.results_summary
    else
      Delayed::Job.enqueue @scraper
      flash.now[:notice] = "Scraper is being processed and you will be emailed with the results"
    end
    @parser = @scraper.parser
    render :action => :show
  end
  
  private
  def find_scraper
    @scraper = Scraper.find(params[:id])
  end
  
end
