class DatasetTopicsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_dataset_topic
  def show
    @title = @dataset_topic.title
    @datapoints = @dataset_topic.datapoints.all(:conditions => {"area_type" => "Council"}, :limit => 10, :include => [:area], :order => "(datapoints.value + 0) DESC")
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
