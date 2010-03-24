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
    @user_submission.approved = params[:approve]
    @user_submission.update_attributes!(params[:user_submission])
    flash[:notice] = "Successfully updated submission"
    redirect_to admin_url
  rescue Exception => e
    flash[:notice] = "Problem updating submission: #{e.inspect}"
    redirect_to edit_user_submission_url(@user_submission) and return
  end
end
