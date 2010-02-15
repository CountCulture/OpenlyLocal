 # Mixin with bunch of useful methods for models with twitter accounts
module TwitterAccountMethods
  module ClassMethods
    # delegate :name, :to => "new_twitter_account", :prefix => :twitter_account
  end
  
  module InstanceMethods
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
    receiver.has_one :new_twitter_account, :class_name => "TwitterAccount", :as => :user
    receiver.delegate :name, :to => "new_twitter_account", :prefix => :twitter_account, :allow_nil => true
    receiver.delegate :url, :to => "new_twitter_account", :prefix => :twitter_account, :allow_nil => true
  end
end