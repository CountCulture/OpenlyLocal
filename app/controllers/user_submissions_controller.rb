class UserSubmissionsController < ApplicationController
  before_filter :authenticate, :only => :update
  
  def new
    @user_submission = UserSubmission.new(:member_id => params[:member_id])
    @title = "New twitter/blog etc details for councillor"
  end
  
  def create
    @user_submission = UserSubmission.new(params[:user_submission])
    @user_submission.council = @user_submission.member.council if @user_submission.member
    @user_submission.save!
    flash[:notice] = "Details successfully submitted. We will review it ASAP" #" and will <a href='http://twitter.com/OpenlyLocal'>tweet</a> when it is approved"
    redirect_to council_url(@user_submission.council)
  rescue
    render :action => "new"
  end
  
  def update
    user_submission = UserSubmission.find(params[:id])
    if member = user_submission.member
      member.update_from_user_submission(user_submission)
      flash[:notice] = "Successfully updated #{member.full_name} from user_submission"
    else
      flash[:notice] = "Problem updating from user_submission: No associated member"
    end
    redirect_to admin_url
  end
end
