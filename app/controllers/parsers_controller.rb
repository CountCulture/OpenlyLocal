class ParsersController < ApplicationController
  before_filter :authenticate
  skip_before_filter :share_this
  newrelic_ignore

  def show
    @parser = Parser.find(params[:id])
    @scrapers = @parser.scrapers
  end
  
  def new
    raise ArgumentError unless params[:portal_system_id]&&params[:scraper_type]
    parser_params = {:portal_system_id => params[:portal_system_id], :result_model => params[:result_model], :scraper_type => params[:scraper_type]}
    # parser_params = params.only(:portal_system_id, :result_model, :scraper_type)
    @parser = params[:scraper_type] =='CsvScraper' ? CsvParser.new(parser_params) : Parser.new(parser_params)
  end
  
  def edit
    @parser = Parser.find(params[:id])
  end
  
  def create
    @parser = params[:parser] ? Parser.new(params[:parser]) : CsvParser.new(params[:csv_parser])
    @parser.save!
    flash[:notice] = "Successfully created parser"
    redirect_to parser_path(@parser)
  rescue
    render :action => "new"
  end
  
  def update
    @parser = Parser.find(params[:id])
    @parser.update_attributes!(@parser.is_a?(CsvParser) ? params[:csv_parser] : params[:parser])
    flash[:notice] = "Successfully updated parser"
    redirect_to parser_url(@parser)
  rescue Exception => e
    flash[:notice] = "Problem updating parser"
    logger.debug { "Problem updating parser: #{e.inspect}\n #{e.backtrace}" }
    render :action => "edit"
  end
  
end
