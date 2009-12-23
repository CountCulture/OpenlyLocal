class HyperlocalSite < ActiveRecord::Base
  validates_presence_of :title, :url
  validates_uniqueness_of :title
  validates_uniqueness_of :url
end
