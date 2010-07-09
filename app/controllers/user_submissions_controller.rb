class UserSubmissionsController < ApplicationController
  before_filter :authenticate, :except => [:new, :create]
  
  def new
    # @user_submission = UserSubmission.new(:council_id => params[:council_id], :member_id => params[:member_id])
    @item = params[:item_type].constantize.find(params[:item_id])
    @user_submission = UserSubmission.new(:submission_type => params[:submission_type], :item => @item)
    @title = "New #{params[:submission_type].titleize}"
  end
  
  def create
    @user_submission = UserSubmission.new(params[:user_submission].merge(:ip_address => request.remote_ip))
    @user_submission.save!
    flash[:notice] = "Details successfully submitted. We will review it ASAP" #" and will <a href='http://twitter.com/OpenlyLocal'>tweet</a> when it is approved"
    redirect_to @user_submission.item
  rescue
    render :action => "new"
  end
  
  def edit
    @user_submission = UserSubmission.find(params[:id])
    @title = "Edit submission"
  end
  
  def update
    @user_submission = UserSubmission.find(params[:id])
    @user_submission.update_attributes(params[:user_submission]) if params[:user_submission]
    # @user_submission.approve if params[:approve]
    if (params[:approve] && @user_submission.approve) || @user_submission.errors.blank?
      flash[:notice] = "Successfully updated submission"
      redirect_to admin_url
    else
      flash[:notice] = "Problem updating submission"
      redirect_to edit_user_submission_url(@user_submission)
    end
  end
  
  def destroy
    @user_submission = UserSubmission.find(params[:id])
    @user_submission.destroy
    flash[:notice] = "Successfully destroyed submission"
    redirect_to admin_url
  end
  
end
