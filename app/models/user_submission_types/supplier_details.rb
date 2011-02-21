class SupplierDetails < UserSubmissionDetails
  attr_accessor :url, :source_for_info, :company_number, :charity_number, :wikipedia_url, :resource_uri

  def initialize(params={})
    super
    @url = TitleNormaliser.normalise_url(@url)
  end
  
  def approve(submission)
    submission.item.update_supplier_details(self) rescue return false
  end
  
end