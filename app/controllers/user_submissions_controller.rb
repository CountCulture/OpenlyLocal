class UserSubmissionsController < ApplicationController
  before_filter :authenticate, :except => [:new, :create]
  
  def new
    if Hash === params[:user_submission] && params[:user_submission][:submission_type]
      @user_submission = UserSubmission.new(params[:user_submission])
      @item = @user_submission.item
      # @possible_entities = @user_submission.submission_details.entity_type.constantize.all if @user_submission.submission_details.entity_type
      @possible_entities = GenericEntityMatcher.possible_matches(:title => @item.title, :type => @user_submission.submission_details.entity_type)[:result] if @user_submission.submission_details.entity_type

      @form_params = ((@user_submission.submission_type == 'supplier_details') && !@possible_entities) ? {:url => new_user_submission_path, :html => {:method => :get}} : {}
      @title = "New #{@user_submission.submission_type.titleize}"
    else
      flash[:notice] = "Sorry, we couldn't render the user submission form."
      redirect_to request.env['HTTP_REFERER'] ? :back : root_path
    end
  end
  
  def create
    @user_submission = UserSubmission.new(params[:user_submission].merge(:ip_address => request.remote_ip))
    if @user_submission.save
      flash[:notice] = "Details successfully submitted. We will review it ASAP" #" and will <a href='http://twitter.com/OpenlyLocal'>tweet</a> when it is approved"
      redirect_to @user_submission.item
    else
      render :action => 'new'
    end
  end
  
  def edit
    @user_submission = UserSubmission.find(params[:id])
    @title = "Edit submission"
  end
  
  def update
    @user_submission = UserSubmission.find(params[:id])
    @user_submission.update_attributes(params[:user_submission]) if params[:user_submission]
    if (params[:approve] && @user_submission.approve) || (!params[:approve] && @user_submission.errors.blank?)
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
