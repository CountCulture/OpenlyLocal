module TitleNormaliser

  extend self

  
  def normalise(raw_title)
    return unless raw_title
    raw_title = raw_title.gsub(/committee|cttee|the /mi, '').gsub('&', ' and ').gsub('-', ' ').downcase.squish 
  end
end
