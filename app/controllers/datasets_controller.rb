class DatasetsController < ApplicationController
  before_filter :authenticate, :except => [:show, :index]
  before_filter :find_dataset, :except => [:index]
  caches_action :show, :cache_path => Proc.new { |controller| controller.params }, :expires_in => 1.day
  
  def index
    @datasets = Dataset.all
    @title = "All Datasets"
  end
  
  def show
    @area = params[:area_type].camelize.constantize.find(params[:area_id]) if params[:area_type]&&params[:area_id]
    @title = @area ? "#{@area.title} :: #{@dataset.title}" : @dataset.title
    if @area
      @datapoints = @dataset.calculated_datapoints_for(@area)
      @statistics_table_description = :subject
      @table_caption = "#{@dataset.title} <em>for #{@area.title}</em>"
    else
      @datapoints = @dataset.calculated_datapoints_for_councils
      @statistics_table_description = :area
      @table_caption = "#{@dataset.title} <em>by council</em>"
    end
  end
  
  def edit
  end
  
  def update
    @dataset.update_attributes!(params[:dataset])
    flash[:notice] = "Successfully updated dataset (#{@dataset.title})"
    redirect_to dataset_url(@dataset)
  end
  
  private
  def find_dataset
    @dataset = Dataset.find(params[:id])
  end
end
