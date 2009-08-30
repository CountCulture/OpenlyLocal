module NameParser

  extend self

  Titles = %w(Mrs Mr Miss Professor Prof Dr Doctor Ms The Deputy Right Honourable the Lord Mayor High Sheriff) # NB order is important
  Qualifications = %w(B.Sc. M.B.A. B.A. M.A. Ph.D. B.Ed. D.Phil. M.B.E. C.B.E. O.B.E. J.P. F.CMI F.R.C.S. Hons. MInstTA)
  
  def parse(fn)
    poss_quals = Qualifications + Qualifications.map{|e| e.gsub('.','')}
    titles, qualifications, result_hash = [], [], {}
    fn = fn.sub(/(Councillor|Councilllor|Cllr|Councillior|CC)\b/, '')
    titles = Titles.select{ |t| fn.sub!(Regexp.new("#{t}.?\s"),'')}
    fn.strip! #sho initials should have no white space before them
    qualifications = poss_quals.select{ |q| fn.sub!(Regexp.new("\s#{Regexp.escape(q)}"),'')}.compact
    names = fn.gsub(/([.,])/, ' ').gsub(/\([\w ]+\)/, '').gsub(/(\s[A-Z]{3,})+$/, '').split(" ")

    result_hash[:first_name] = names[0..-2].join(" ")
    result_hash[:last_name] = names.last
    result_hash[:name_title] = titles.join(" ") unless titles.empty?
    result_hash[:qualifications] = qualifications.join(" ") unless qualifications.empty?
    result_hash
  end
end