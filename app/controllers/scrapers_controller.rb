class ScrapersController < ApplicationController
  before_filter :find_scraper, :except => [:index, :new, :create]
  before_filter :create_stub_scraper, :only => [:create]
  before_filter :authenticate
  skip_before_filter :share_this
  newrelic_ignore
  
  def index
    @councils_with_scrapers, @councils_without_scrapers = Council.find(:all, :include => { :scrapers => { :parser => :portal_system, :council => {} } }, 
                                                                             :order => "councils.name" ).partition{ |c| !c.scrapers.empty? }
    @title = "All scrapers"
  end
  
  def show
    @title = @scraper.title
    @parser = @scraper.parser
    @scrapes = @scraper.scrapes.recent.all
  end
  
  def new
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    @council = Council.find(params[:council_id]) if params[:council_id]
    @scraper = params[:type].camelize.constantize.new(:council_id => params[:council_id])
    parser_type = @scraper.is_a?(CsvScraper) ? 'CsvParser' : 'Parser'
    parser = 
      case 
      when params[:parser_id]
        Parser.find(params[:parser_id])
      when ps_id = params[:portal_system_id] || (@council&&@council.portal_system_id)
        Parser.find_by_portal_system_id_and_result_model_and_scraper_type(ps_id, params[:result_model], params[:type])
      else
        nil
      end
    @scraper.parser = parser || parser_type.constantize.new( :result_model => params[:result_model], :scraper_type => params[:type])
  end
  
  def create
    if @scraper.save
      flash[:notice] = "Successfully created scraper"
      redirect_to scraper_url(@scraper)
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @scraper.update_attributes(params[:scraper])
      flash[:notice] = "Successfully updated scraper"
      redirect_to scraper_url(@scraper)
    else
      render :action => 'edit'
    end
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
      @scraper.enqueue(2)
      flash.now[:notice] = "Scraper is being processed and you will be emailed with the results"
    end
    @parser = @scraper.parser
    render :action => :show
  end
  
  private
  
  # Override default auth_level to allow more granular authentication. Allows people with access to 
  # :planning_applications, for example, to see and edit planning_application scrapers
  def auth_level
    case 
    when @scraper
      @scraper.result_model.underscore.pluralize
    when result_model = params[:result_model]
      result_model.underscore.pluralize
    else
      'scrapers'
    end
  end
  
  # This creates an unsaved scraper, as needed by :create (and helps us to have more granular authentication)
  def create_stub_scraper
    raise ArgumentError unless Scraper::SCRAPER_TYPES.include?(params[:type])
    @scraper = params[:type].camelize.constantize.new(params[:scraper])
  end
  
  def find_scraper
    @scraper = Scraper.find(params[:id])
  end
  
end
