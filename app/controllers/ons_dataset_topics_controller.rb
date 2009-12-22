class OnsDatasetTopicsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_ons_dataset_topic
  def show
    @title = @ons_dataset_topic.title
  end

  def edit
  end
  
  def populate
    Delayed::Job.enqueue @ons_dataset_topic
    flash[:notice] = "Successfully queued Topic to be populated for all councils. You will be emailed when this has finished"
    redirect_to ons_dataset_topic_url(@ons_dataset_topic)
  end
  
  def update
    @ons_dataset_topic.update_attributes!(params[:ons_dataset_topic])
    flash[:notice] = "Successfully updated OnsDatasetTopic"
    redirect_to ons_dataset_topic_url(@ons_dataset_topic)
  end

  private
  def find_ons_dataset_topic
    @ons_dataset_topic = OnsDatasetTopic.find(params[:id])
  end
end
