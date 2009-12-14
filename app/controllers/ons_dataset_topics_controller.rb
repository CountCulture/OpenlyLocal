class OnsDatasetTopicsController < ApplicationController
  def show
    @ons_dataset_topic = OnsDatasetTopic.find(params[:id])
    @title = @ons_dataset_topic.title
  end

end
