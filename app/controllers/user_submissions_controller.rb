class UserSubmissionsController < ApplicationController
  before_filter :authenticate, :except => [:new, :create]
  
  def new
    @user_submission = UserSubmission.new(:council_id => params[:council_id], :member_id => params[:member_id])
    @title = "New social networking info for councillor"
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
  
  def edit
    @user_submission = UserSubmission.find(params[:id])
    @title = "Edit submission"
  end
  
  def update
    @user_submission = UserSubmission.find(params[:id])
    member = @user_submission.member
    if params[:approve] && member
      member.update_from_user_submission(@user_submission)
      flash[:notice] = "Successfully updated member #{member.full_name} from user_submission"
    elsif params[:approve] && !member
      flash[:notice] = "Can't find member named #{@user_submission.member_name}"
    else
      @user_submission.update_attributes(params[:user_submission])
      flash[:notice] = "Successfully updated submission"
    end
    redirect_to admin_url
  end
end
