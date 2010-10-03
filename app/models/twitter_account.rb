class TwitterAccount < ActiveRecord::Base
  belongs_to :user, :polymorphic => true
  validates_presence_of :name, :user_type, :user_id
  alias_attribute :title, :name
  after_save :add_to_twitter_list, :remove_from_twitter_list
  after_destroy :remove_from_twitter_list
  
  def list_name
    self.user.twitter_list_name
  end
  
  def url
    "http://twitter.com/#{name}"
  end
  
  protected
  def add_to_twitter_list
    return unless changes['name'] && !list_name.blank?
    Delayed::Job.enqueue(Tweeter.new(:method => :add_to_list, :user => name, :list => list_name))
  end
  
  def remove_from_twitter_list
    return unless (destroyed? || (name_changed?&&name_change.first) ) && !list_name.blank?
    t_name = destroyed? ? name : name_change.first
    Delayed::Job.enqueue(Tweeter.new(:method => :remove_from_list, :user => t_name, :list => list_name))
  end

end
