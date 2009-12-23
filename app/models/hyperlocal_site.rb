class HyperlocalSite < ActiveRecord::Base
  belongs_to :hyperlocal_group
  validates_presence_of :title, :url
  validates_uniqueness_of :title
  validates_uniqueness_of :url
end
