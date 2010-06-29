class SocialNetworkingDetails < UserSubmissionDetails
  attr_accessor :blog_url, :twitter_account_name, :facebook_account_name
  
  def approve(submission)
    puts "**** about to run SocialNetworkingDetails#approve"
    submission.item.update_social_networking_details(self) rescue return false
  end
end