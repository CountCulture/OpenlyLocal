class ParsersController < ApplicationController
  before_filter :find_parser, :except => [:index, :new, :create]
  before_filter :authenticate
  skip_before_filter :share_this
  newrelic_ignore

  def show
    @scrapers = @parser.scrapers
  end
  
  def new
    raise ArgumentError unless params[:portal_system_id]&&params[:scraper_type]
    parser_params = {:portal_system_id => params[:portal_system_id], :result_model => params[:result_model], :scraper_type => params[:scraper_type]}
    # parser_params = params.only(:portal_system_id, :result_model, :scraper_type)
    @parser = params[:scraper_type] =='CsvScraper' ? CsvParser.new(parser_params) : Parser.new(parser_params)
  end
  
  def edit
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
    @parser.update_attributes!(@parser.is_a?(CsvParser) ? params[:csv_parser] : params[:parser])
    flash[:notice] = "Successfully updated parser"
    redirect_to parser_url(@parser)
  rescue Exception => e
    flash[:notice] = "Problem updating parser"
    logger.debug { "Problem updating parser: #{e.inspect}\n #{e.backtrace}" }
    render :action => "edit"
  end
  
  private
  # Override default auth_level to allow more granular authentication. Allows people with access to 
  def auth_level
    case 
    when @parser
      @parser.result_model.underscore.pluralize
    when result_model = params[:result_model] || params[:parser] && params[:parser][:result_model]
      result_model.underscore.pluralize
    else
      'parsers'
    end
  end
  
  def find_parser
    @parser = Parser.find(params[:id])
    
  end
  
end
