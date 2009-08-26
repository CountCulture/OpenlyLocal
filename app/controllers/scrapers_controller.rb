class ScrapersController < ApplicationController
  before_filter :authenticate
  skip_before_filter :share_this
  newrelic_ignore
  
  def index
    @councils = Council.find(:all, :include => :scrapers, :order => "name")
    @title = "All scrapers"
  end
  
  def show
    @scraper = Scraper.find(params[:id])
    @title = @scraper.title
    if params[:dry_run]
      @results = @scraper.process.results
    elsif params[:process] == "immediately"
      @results = @scraper.process(:save_results => true).results
    elsif params[:process]
      Delayed::Job.enqueue @scraper
      flash[:notice] = "Scraper is being processed and you will be emailed with the results"
    end
    @parser = @scraper.parser
  end
  
  def new
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type]) && params[:council_id]
    @council = Council.find(params[:council_id])
    @scraper = params[:type].constantize.new(:council_id => @council.id)
    parser = @council.portal_system_id ? Parser.find_by_portal_system_id_and_result_model_and_scraper_type(@council.portal_system_id, params[:result_model], params[:type]) : nil
    parser ? (@scraper.parser = parser) : @scraper.build_parser(:result_model => params[:result_model], :scraper_type => params[:type])
  end
  
  def create
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    @scraper = params[:type].constantize.new(params[:scraper])
    @scraper.save!
    flash[:notice] = "Successfully created scraper"
    redirect_to scraper_url(@scraper)
  end
  
  def edit
    @scraper = Scraper.find(params[:id])
  end
  
  def update
    @scraper = Scraper.find(params[:id])
    @scraper.update_attributes!(params[:scraper])
    flash[:notice] = "Successfully updated scraper"
    redirect_to scraper_url(@scraper)
  end
  
  def destroy
    @scraper = Scraper.find(params[:id])
    @scraper.destroy
    flash[:notice] = "Successfully destroyed scraper"
    redirect_to scrapers_url(:anchor => "council_#{@scraper.council_id}")
  end
  
end
