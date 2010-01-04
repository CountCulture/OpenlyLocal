class DatasetsController < ApplicationController
  def index
    @datasets = Dataset.all
    @title = "All Datasets"
  end
  
  def show
    @dataset = Dataset.find(params[:id])
    @area = params[:area_type].constantize.find(params[:area_id]) if params[:area_type]&&params[:area_id]
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
end
