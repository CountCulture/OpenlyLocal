class TwitterAccountsController < ApplicationController
  
  def index
    @twitter_accounts = TwitterAccount.all(:conditions => {:user_type => params[:user_type].classify})
    @title = "Twitter accounts"
  end
  
  def show
    @twitter_account = TwitterAccount.find(params[:id])
    @title = "Twitter account for #{@twitter_account.user.title} (#{@twitter_account.name})"
  end
  
end
