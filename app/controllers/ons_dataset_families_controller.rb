class OnsDatasetFamiliesController < ApplicationController
  def index
    @statistical_datasets = StatisticalDataset.all(:include => [:ons_dataset_families])
  end

  def show
    @ons_dataset_family = OnsDatasetFamily.find(params[:id])
    @area = params[:area_type].constantize.find(params[:area_id]) if params[:area_type]&&params[:area_id]
    @title = @area ? "#{@area.title} :: #{@ons_dataset_family.title}" : @ons_dataset_family.title
    if @area
      @datapoints = @ons_dataset_family.ons_datapoints.all(:conditions => {:area_type => params[:area_type], :area_id => params[:area_id] }).sort_by{ |d| d.ons_dataset_topic.title }
      @statistics_table_subject = :ons_dataset_topic
    else
      @datapoints = @ons_dataset_family.calculated_datapoints_for_councils
      @statistics_table_subject = :area
    end
  end

end
