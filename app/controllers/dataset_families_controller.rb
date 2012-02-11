class DatasetFamiliesController < ApplicationController
  caches_action :show, :expires_in => 1.day

  def index
    @datasets = Dataset.all(:include => [:dataset_families])
  end

  def show
    @dataset_family = DatasetFamily.find(params[:id])
    @area = params[:area_type].constantize.find(params[:area_id]) if params[:area_type]&&params[:area_id]
    @title = @area ? "#{@dataset_family.title} :: #{@area.title}" : @dataset_family.title
    if @area
      @datapoints = @dataset_family.datapoints.all(:conditions => {:area_type => params[:area_type], :area_id => params[:area_id] }).sort_by{ |d| d.dataset_topic.title }
      @statistics_table_description = :dataset_topic
    else
      @datapoints = @dataset_family.calculated_datapoints_for_councils
      @statistics_table_description = :area
    end
  end

end
