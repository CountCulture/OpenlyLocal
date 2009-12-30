class StatisticalDatasetsController < ApplicationController
  def index
    @statistical_datasets = StatisticalDataset.all
    @title = "All Datasets"
  end
  
  def show
    @statistical_dataset = StatisticalDataset.find(params[:id])
    @title = @statistical_dataset.title  
  end
end
