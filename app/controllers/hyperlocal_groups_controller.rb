class HyperlocalGroupsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_hyperlocal_group, :except => [:new, :create]
  
  def show
    @title = @hyperlocal_group.title
  end

  def new
    @hyperlocal_group = HyperlocalGroup.new
  end
  
  def create
    @hyperlocal_group = HyperlocalGroup.new(params[:hyperlocal_group])
    @hyperlocal_group.save!
    flash[:notice] = "Successfully created hyperlocal group"
    redirect_to hyperlocal_group_url(@hyperlocal_group)
  rescue
    render :action => "new"
  end
  
  def edit
    @title = @hyperlocal_group.title
  end
  
  def update
    @hyperlocal_group.update_attributes!(params[:hyperlocal_group])
    flash[:notice] = "Successfully updated hyperlocal group"
    redirect_to hyperlocal_group_url(@hyperlocal_group)
  end
  
  private
  def find_hyperlocal_group
    @hyperlocal_group = HyperlocalGroup.find(params[:id])
  end
end
