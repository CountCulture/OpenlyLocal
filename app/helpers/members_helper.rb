module MembersHelper
  def social_networking_links_for(member)
    return "None known. #{link_to('Add social networking info now?', new_user_submission_path(:member_id => member.id))}" unless member.twitter_account_name || member.facebook_account_name?
    [twitter_link_for(member.twitter_account_name), facebook_link_for(member.facebook_account_name)].compact.join(' ')
  end
end
