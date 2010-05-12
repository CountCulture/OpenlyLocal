module NameParser

  extend self

  Titles = %w(Professor Prof Sir Mrs Mr Miss Dr Doctor Ms The Deputy Right Honourable the Lord Mayor High Sheriff) # NB order is important
  Qualifications = %w(B.Sc. M.B.A. B.A. M.A. A.M. Ph.D. B.Ed. D.Phil. M.B.E. C.B.E. O.B.E. J.P. M.P. F.CMI F.R.C.S. L.L.B. Hons. MInstTA Cert.Ed CEng MRPharmS)
  
  def parse(fn)
    return unless fn
    return {:last_name => 'Vacancy'} if fn.match(/vacan[tc]/i)
    poss_quals = Qualifications + Qualifications.map{|e| e.gsub('.','')}
    titles, qualifications, result_hash = [], [], {}
    fn = strip_all_spaces(fn).sub(/(Councillor|Councilor|Councilllor|Cllr|Councillior|CC|County Councillor)\b/, '').sub(/- [A-Za-z ]+$/,'').gsub(/\([\w ]+\)/, '')
    titles = Titles.select{ |t| fn.sub!(Regexp.new("#{t}\\.?\\s"),'')}
    fn.strip! # so initials should have no white space before them
    qualifications = poss_quals.select{ |q| fn.sub!(Regexp.new("\\s#{Regexp.escape(q)}"),'')}.compact
    names = fn.gsub(/([.,])/, ' ').gsub(/(\s[A-Z]{3,})+$/, '').split(" ")

    result_hash[:first_name] = names[0..-2].join(" ")
    result_hash[:last_name] = names.last
    result_hash[:name_title] = titles.join(" ") unless titles.empty?
    result_hash[:qualifications] = qualifications.join(" ") unless qualifications.empty?
    result_hash
  end
  
  #strips spaces and converts unicode spaces (Gpricot turns non-breaking spaces into these) to spaces
  def strip_all_spaces(text)
    text.gsub(/&nbsp;|\xC2\xA0|\xA0/, ' ').strip
  end
end