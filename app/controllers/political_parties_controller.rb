class PoliticalPartiesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :find_political_party, :except => [:index, :new, :create]
  
  def edit
  end
  
  def update
    @political_party.update_attributes!(params[:political_party])
    flash[:notice] = "Successfully updated police force"
    redirect_to political_party_url(@political_party)
  rescue
    render :action => "edit"
  end
  
  private
  def find_political_party
    @political_party = PoliticalParty.find(params[:id])
  end
end
