module IcalUtilities
  PRODID = "Pushrod Ltd//Ical exporter 0.03//EN"
  class Calendar
    attr_reader :attribute_aliases, :events, :name, :url
    def initialize(events=nil, options={})
      @events = (events.is_a?(Array) ? events : [events]).compact # ensure we have array of events, even if there's only one event, or empty array otherwise
      @name, @url, @attribute_aliases = options[:name], options[:url], options[:attribute_aliases]||{}
    end
    
    def encoded
      result  = "BEGIN:VCALENDAR\nVERSION:2.0\nMETHOD:PUBLISH\nPRODID:-//#{PRODID}\nCALSCALE:Gregorian\n"
      result += "X-WR-CALNAME:#{@name}\n" if @name
      result += "X-ORIGINAL-URL:#{@url}\n" if @url
      @events.each do |event|
        result += "BEGIN:VEVENT\n"
        # Add attribute_aliases and remove the ones we're aliasing
        (attribute_aliases.keys + %w(summary dtstart dtend description location organizer created last_modified uid url) - attribute_aliases.values.map(&:to_s)).each do |m|
          next unless event.respond_to?(m)
          raw_attrib = event.send(m)
          attrib_name = attribute_aliases[m] || m
          result += rfc2445_wrap_string("#{attrib_name.to_s.upcase.gsub("_","-")}#{encode_attribute(raw_attrib)}")+"\n" unless raw_attrib.blank?
        end
        result += "END:VEVENT\n"
      end
      result += "END:VCALENDAR\n"
    end
    
    protected
    def encode_attribute(attrib)
      formatted_attrib = 
        case attrib
        when String
          ":#{attrib}"
        when Time
          ":#{attrib.strftime("%Y%m%dT%H%M%S")}"
        when Date
          ";VALUE=DATE:#{attrib.strftime("%Y%m%d")}"
        when Hash
          ";CN=\"#{attrib[:cn]}\":#{attrib[:uri]}"
        end
      rfc2445_escape_string(formatted_attrib)
    end
    
    def rfc2445_escape_string(unescaped_string)
      unescaped_string.gsub(/\r\n/, "\n").gsub(/\n/, "\\n")
    end
    
    def rfc2445_wrap_string(unencoded_string)
      unencoded_string.gsub(/.{75,75}/) { |m| m + "\n " }
    end
  end
  
  module ArrayExtensions
    def to_ical(options={})
      IcalUtilities::Calendar.new(self,options).encoded
    end
  end
end