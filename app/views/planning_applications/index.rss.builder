xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:georss" => "http://www.georss.org/georss" do
  xml.channel do
    xml.title @page_title || @title
    xml.description "#{@page_title || @title} from OpenlyLocal"
    xml.link hyperlocal_sites_url(:format => :rss)
    
    @planning_applications.select{ |pa| pa.lat && pa.lng  }.each do |planning_app|
      xml.item do
        xml.title planning_app.title
        xml.description planning_app.description
        xml.pubDate planning_app.created_at.to_s(:rfc822)
        xml.link planning_application_url(planning_app)
        xml.guid planning_application_url(:id => planning_app.id)
        xml.tag!("georss:point", "#{planning_app.lat} #{planning_app.lng}")
      end
    end
  end
end

