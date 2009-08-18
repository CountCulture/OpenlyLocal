class DocumentsController < ApplicationController
  
  def index
    @council = Council.find(params[:council_id])
    @documents = @council.documents
    @title = "Committee documents"
  end
  
  def show
    @document = Document.find(params[:id])
    @council = @document.document_owner.council
    @title = @document.extended_title
  end

end
