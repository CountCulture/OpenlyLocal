# Mixin with bunch of useful methods for resoures, i.e. those models exposed as resource via api
module ResourceMethods
  
  def dbpedia_resource
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/resource") unless wikipedia_url.blank?
  end
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end