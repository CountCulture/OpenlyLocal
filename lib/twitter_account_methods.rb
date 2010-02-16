 # Mixin with bunch of useful methods for models with twitter accounts
module TwitterAccountMethods
  module ClassMethods
    # delegate :name, :to => "twitter_account", :prefix => :twitter_account
  end
  
  module InstanceMethods
    # convenience method for setting twitter account relationship. Allows us to set by parsing results
    def twitter_account_name=(name)
      if ta = twitter_account 
        name.blank? ? ta.destroy : ta.update_attributes(:name => name)
      else
        create_twitter_account(:name => name)
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
    receiver.has_one :twitter_account, :as => :user, :dependent => :destroy
    receiver.delegate :name, :to => "twitter_account", :prefix => true, :allow_nil => true
    receiver.delegate :url, :to => "twitter_account", :prefix => true, :allow_nil => true
  end
end