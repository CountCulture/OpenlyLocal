module TitleNormaliser

  extend self

  def normalise_title(raw_title)
    return unless raw_title
    raw_title = raw_title.gsub('&', ' and ').gsub(/-/im, ' ').gsub(/-|\:|\'|the /im, '').downcase.squish 
  end
end
