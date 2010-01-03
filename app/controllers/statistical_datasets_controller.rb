class StatisticalDatasetsController < ApplicationController
  def index
    @statistical_datasets = StatisticalDataset.all
    @title = "All Datasets"
  end
  
  def show
    @statistical_dataset = StatisticalDataset.find(params[:id])
    @area = params[:area_type].constantize.find(params[:area_id]) if params[:area_type]&&params[:area_id]
    @title = @area ? "#{@area.title} :: #{@statistical_dataset.title}" : @statistical_dataset.title
    if @area
      @datapoints = @statistical_dataset.calculated_datapoints_for(@area)
      @statistics_table_subject = :ons_dataset_family
    else
      @datapoints = @statistical_dataset.calculated_datapoints_for_councils
      @statistics_table_subject = :area
    end
  end
end
