class DatasetTopicsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_dataset_topic
  caches_action :show

  def show
    if params[:area_type]&&params[:area_id]
      @area = params[:area_type].constantize.find(params[:area_id])
      @council = @area.council if @area.is_a?(Ward)
      @datapoints = @dataset_topic.datapoints.all(:conditions => {:area_type => @area.class.to_s, :area_id => @area.related.collect(&:id)}).sort_by{ |dp| dp.area.title }
      @title = "#{@area.title} :: #{@dataset_topic.title}"
      @table_caption = "Comparison against other " + (@area.is_a?(Ward) ? "wards in #{@council.name}" : "#{@area.authority_type} Councils")
      @selected_datapoint = @datapoints.detect{ |dp| dp.area_id == @area.id }
    else
      # @datapoints = @dataset_topic.datapoints.all(:conditions => {"area_type" => "Council"}, :limit => 10, :include => [:area], :order => "(datapoints.value + 0) DESC")
      @datapoints = @dataset_topic.datapoints.all(:conditions => {"area_type" => "Council"}, :include => [:area], :order => "(datapoints.value + 0) DESC")
      @title = @dataset_topic.title
    end
  end

  def edit
  end
  
  def populate
    Delayed::Job.enqueue @dataset_topic
    flash[:notice] = "Successfully queued Topic to be populated for all councils. You will be emailed when this has finished"
    redirect_to dataset_topic_url(@dataset_topic)
  end
  
  def update
    @dataset_topic.update_attributes!(params[:dataset_topic])
    flash[:notice] = "Successfully updated DatasetTopic"
    redirect_to dataset_topic_url(@dataset_topic)
  end

  private
  def find_dataset_topic
    @dataset_topic = DatasetTopic.find(params[:id])
  end
end
