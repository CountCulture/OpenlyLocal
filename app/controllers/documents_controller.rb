class DocumentsController < ApplicationController
  
  def index
    @council = Council.find(params[:council_id])
    @documents = params[:term] ? @council.documents.find(:all, :conditions => ["body LIKE ?", "%#{params[:term]}%"] ) : @council.documents
    @title = params[:term] ? "Committee documents with '#{params[:term]}'" : "Committee documents"
    respond_to do |format|
      format.html
      format.xml { render :xml => @documents.to_xml }
      format.json { render :json => @documents.to_json }
    end
  end
  
  def show
    @document = Document.find(params[:id])
    @council = @document.document_owner.council
    @title = @document.extended_title
  end

end
