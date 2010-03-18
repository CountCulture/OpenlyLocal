class PoliticalPartiesController < ApplicationController
  before_filter :authenticate
  before_filter :find_political_party, :except => [:index, :new, :create]
  
  def index
    @political_parties = PoliticalParty.all
    @title = "UK Political Parties"
  end
  
  def edit
  end
  
  def update
    @political_party.update_attributes!(params[:political_party])
    flash[:notice] = "Successfully updated political party"
    redirect_to political_parties_url
  rescue
    render :action => "edit"
  end
  
  private
  def find_political_party
    @political_party = PoliticalParty.find(params[:id])
  end
end
