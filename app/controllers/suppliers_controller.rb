class SuppliersController < ApplicationController
  
  def index
    @organisation = params[:organisation_type].constantize.find(params[:organisation_id]) if params[:organisation_type] && params[:organisation_id]
    @title = @organisation ? "Suppliers to #{@organisation.title}" : 'Suppliers to Local Authorities'
    @suppliers = @organisation ? @organisation.suppliers.paginate(:page => params[:page], :order => 'name') : Supplier.paginate(:page => params[:page], :order => 'name')
    @title += " :: Page #{(params[:page]||1).to_i}"
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @suppliers.to_xml { |xml|
                    xml.tag! 'total-entries', @suppliers.total_entries
                    xml.tag! 'per-page', @suppliers.per_page
                    xml.tag! 'page', (params[:page]||1).to_i
                  }
      end
      format.json do
        render :json => { :page => (params[:page]||1).to_i,
                          :per_page => @suppliers.per_page,
                          :total_entries => @suppliers.total_entries,
                          :suppliers => @suppliers.to_json
                        }
      end
    end
  end
  
  def show
    @supplier = Supplier.find(params[:id])
    @organisation = @supplier.organisation
    @title = @supplier.title
    respond_to do |format|
      format.html
      format.xml { render :xml => @supplier.to_xml(:include => :financial_transactions) }
      format.json { render :as_json => @supplier.to_xml(:include => :financial_transactions) }
    end
    
  end
end
