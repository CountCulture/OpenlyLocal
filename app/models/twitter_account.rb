class TwitterAccount < ActiveRecord::Base
  belongs_to :user, :polymorphic => true
  validates_presence_of :name, :user_type, :user_id
  alias_attribute :title, :name
  
  def url
    "http://twitter.com/#{name}"
  end

end
