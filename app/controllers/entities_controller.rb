class EntitiesController < ApplicationController
  before_filter :authenticate, :except => [:index, :show, :show_spending]
  before_filter :find_entity, :except => [:index, :new, :create]
  before_filter :linked_data_available, :only => :show
  caches_page :show, :expires_in => 12.hours

  def index
    @entities = Entity.all(:order => 'title')
    @title = 'Quangos, associations and other organisations'
    respond_to do |format|
      format.html
      format.xml { render :xml => @entities.to_xml }
      format.json { render :json => @entities.to_json }
    end
  end
  
  def show
    @title = "#{@entity.title} :: Entitys"
    respond_to do |format|
      format.html
      format.xml { render :xml => @entity.to_xml}#(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.json { render :as_json => @entity.to_xml}#(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.rdf 
    end
  end
  
  def new
    @entity = Entity.new    
  end
  
  def create
    @entity = Entity.new(params[:entity])
    @entity.save!
    flash[:notice] = "Successfully created entity"
    redirect_to entity_url(@entity)
  rescue
    render :action => "new"
  end
  
  def edit
  end
  
  def update
    @entity.update_attributes!(params[:entity])
    flash[:notice] = "Successfully updated entity"
    redirect_to entity_url(@entity)
  rescue
    render :action => "edit"
  end
  
  def destroy
    @entity.destroy
    flash[:notice] = "Successfully destroyed entity"
    redirect_to entities_url
  end
  
  def show_spending
    @suppliers = @entity.suppliers.all( :joins => :spending_stat, 
                                        :order => 'spending_stats.total_spend DESC', 
                                        :include => :spending_stat, 
                                        :limit => 10)
    @financial_transactions = @entity.payments.all( :from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_value)',
                                                    :include => :supplier, 
                                                    :order => 'value DESC', 
                                                    :limit => 10)
    @title = "Spending Dashboard :: #{@entity.title}"
  end
  
  private
  def find_entity
    @entity = Entity.find(params[:id])
  end
end
