module TitleNormaliser

  extend self

  def normalise_title(raw_title)
    return unless raw_title
    raw_title.gsub('&', ' and ').gsub(/-/im, ' ').gsub(/\.\s/im, ' ').gsub(/-|\:|\'|the /im, '').downcase.squish 
  end
  
  def normalise_company_title(raw_title)
    return unless raw_title
    semi_normed_title = raw_title.gsub(/\bT\/A\b.+/i, '').gsub(/\./,'').sub(/ltd/i, 'limited').sub(/public limited company/i, 'plc')
    normalise_title(semi_normed_title).downcase
  end
  
end
