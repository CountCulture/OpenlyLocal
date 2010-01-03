class OldDatapoint < ActiveRecord::Base
  belongs_to :council
  belongs_to :old_dataset
  validates_presence_of :data, :council_id, :old_dataset_id
  serialize :data
  delegate :summary_column, :to => :old_dataset
  
  def summary
    data.collect{ |d| d[summary_column] } if summary_column
  end
end
