class DatasetTopicGroupingsController < ApplicationController
  before_filter :authenticate
  before_filter :find_dataset_topic_grouping, :except => [:index, :new, :create]
  
  def index
    @dataset_topic_groupings = DatasetTopicGrouping.all
    @title = "Dataset Topic Groupings"
  end
  
  def show
    @title = @dataset_topic_grouping.title
  end
  
  def new
    @dataset_topic_grouping = DatasetTopicGrouping.new    
  end
  
  def create
    @dataset_topic_grouping = DatasetTopicGrouping.new(params[:dataset_topic_grouping])
    @dataset_topic_grouping.save!
    flash[:notice] = "Successfully created grouping (#{@dataset_topic_grouping.title})"
    redirect_to dataset_topic_grouping_url(@dataset_topic_grouping)
  rescue
    render :action => "new"
  end 
  
  def update
    @dataset_topic_grouping.update_attributes!(params[:dataset_topic_grouping])
    flash[:notice] = "Successfully updated grouping (#{@dataset_topic_grouping.title})" 
    redirect_to dataset_topic_grouping_url(@dataset_topic_grouping)
  end
  
  def destroy
    @dataset_topic_grouping.destroy
    flash[:notice] = "Successfully destroyed grouping (#{@dataset_topic_grouping.title})"
    redirect_to dataset_topic_groupings_url
  end
  
  private
  def find_dataset_topic_grouping
    @dataset_topic_grouping = DatasetTopicGrouping.find(params[:id])
  end
end
