xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:georss" => "http://www.georss.org/georss" do
  xml.channel do
    xml.title "Latest #{@title}"
    xml.description "Latest #{@title} from OpenlyLocal"
    xml.link documents_url(:format => :rss)
    
    for site in @hyperlocal_sites.sort_by{ |s| -s.created_at.to_i }[0..19]
      xml.item do
        xml.title site.title
        xml.description site.description
        xml.pubDate site.created_at.to_s(:rfc822)
        xml.link hyperlocal_site_url(site)
        xml.guid hyperlocal_site_url(:id => site.id)
        xml.tag!("georss:point", "#{site.lat} #{site.lng}")
        xml.tag!("georss:radius", site.distance_covered*1604.34) if site.distance_covered?
      end
    end
  end
end

