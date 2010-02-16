 # Mixin with bunch of useful methods for models with twitter accounts
module TwitterAccountMethods
  module ClassMethods
    # delegate :name, :to => "new_twitter_account", :prefix => :twitter_account
  end
  
  module InstanceMethods
    # convenience method for setting twitter account relationship. Allows us to set by parsing results
    def twitter_account_name=(name)
      if ta = new_twitter_account 
        ta.update_attributes(:name => name)
      else
        create_new_twitter_account(:name => name)
      end
    end
    
    # stub method for twitter list name. This is used to update list for twitter account. 
    # By default returns nil. Override in models with lists that need maintaining to
    # return string name of twitter_list, e.g. 'ukcouncillors'
    def twitter_list_name
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
    receiver.has_one :new_twitter_account, :class_name => "TwitterAccount", :as => :user
    receiver.delegate :name, :to => "new_twitter_account", :prefix => :twitter_account, :allow_nil => true
    receiver.delegate :url, :to => "new_twitter_account", :prefix => :twitter_account, :allow_nil => true
  end
end