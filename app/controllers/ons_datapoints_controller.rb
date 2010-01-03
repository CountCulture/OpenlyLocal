class DatapointsController < ApplicationController
  helper :wards
  
  def index
    @dataset_topic = DatasetTopic.find(params[:dataset_topic_id])
    # @dataset_topic.datapoints.limited_to(params.only(:group, :group_id))
  end
  
  def show
    @datapoint = Datapoint.find(params[:id])
    @area = @datapoint.area
    @council = @area.council if @area.is_a?(Ward)
    @datapoints = @datapoint.related_datapoints
    @title = "#{@area.title} :: #{@datapoint.title}"
    @table_caption = "Comparison against other " + (@area.is_a?(Ward) ? "wards in #{@council.name}" : "#{@area.authority_type} Councils")
  end

end
