class SuppliersController < ApplicationController
  caches_action :show, :cache_path => Proc.new { |controller| controller.params }, :expires_in => 12.hours
  
  def index
    search_filter = params[:name_filter]
    page = (params[:page]||1).to_i
    page = 50 if page > 50
    @organisation = params[:organisation_type].constantize.find(params[:organisation_id]) if params[:organisation_type] && params[:organisation_id]
    @title = @organisation ? "Suppliers to #{@organisation.title}" : 'Suppliers to Local Authorities'
    sort_order = params[:order] == 'total_spend' ? 'spending_stats.total_spend DESC' : 'name'
    @suppliers = @organisation ? @organisation.suppliers.paginate(:joins => :spending_stat, :page => page, :order => sort_order) : 
                                 Supplier.filter_by(:name => params[:name_filter]).paginate(:joins => :spending_stat, :page => page, :order => sort_order)
    @title += " :: Page #{page}"
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @suppliers.to_xml { |xml|
                    xml.tag! 'total-entries', @suppliers.total_entries
                    xml.tag! 'per-page', @suppliers.per_page
                    xml.tag! 'page', page
                  }
      end
      format.json do
        render :json => { :page => page,
                          :per_page => @suppliers.per_page,
                          :total_entries => @suppliers.total_entries,
                          :suppliers => @suppliers
                        }
      end
    end
  end
  
  def show
    @supplier = Supplier.find(params[:id])
    @organisation = @supplier.organisation
    order = params[:order] == 'value' ? 'value DESC' : nil
    @financial_transactions = @supplier.financial_transactions.all(:order => order)
    @title = "#{@supplier.title} :: Supplier to #{@organisation.title}"
    respond_to do |format|
      format.html
      format.xml { render :xml => @supplier.to_xml(:include => [:financial_transactions, :payee]) }
      format.json { render :as_json => @supplier.to_xml(:include => [:financial_transactions, :payee]) }
    end
    
  end
end
