class ScrapersController < ApplicationController
  before_filter :authenticate
  skip_before_filter :share_this
  newrelic_ignore
  
  def index
    @councils_with_scrapers, @councils_without_scrapers = Council.find(:all, :include => :scrapers, :order => "name").partition{ |c| !c.scrapers.empty? }
    @title = "All scrapers"
  end
  
  def show
    @scraper = Scraper.find(params[:id])
    @title = @scraper.title
    if params[:dry_run]
      @results = @scraper.process.results
      @results_summary = @scraper.results_summary
    elsif params[:process] == "immediately"
      @results = @scraper.process(:save_results => true).results
      @results_summary = @scraper.results_summary
    elsif params[:process]
      Delayed::Job.enqueue @scraper
      flash.now[:notice] = "Scraper is being processed and you will be emailed with the results"
    end
    @parser = @scraper.parser
  end
  
  def new
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type]) && params[:council_id]
    @council = Council.find(params[:council_id])
    @scraper = params[:type].constantize.new(:council_id => @council.id)
    parser_type = params.delete(:parser_type) || 'Parser'
    parser = @council.portal_system_id ? Parser.find_by_portal_system_id_and_result_model_and_scraper_type(@council.portal_system_id, params[:result_model], params[:type]) : nil
    @scraper.parser = parser ? parser : 
                               parser_type.constantize.new( :result_model => params[:result_model], 
                                                            :scraper_type => params[:type])
  end
  
  def create
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    # parser_type = params[:scraper].delete(:parser_type) || 'Parser'
    # parser = parser_type.constantize.new(params.delete(:parser_attributes))
    # @scraper = params[:type].constantize.new(params[:scraper].merge( :parser => parser))
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
    @scraper.update_attributes(params[:scraper])
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
