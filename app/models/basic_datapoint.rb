class BasicDatapoint
  attr_reader :name, :data, :licence, :source, :source_url
  def initialize(args)
    %w(name data licence source source_url).each do |a|
      instance_variable_set("@#{a}", args[a.to_sym])
    end
  end
  
  def to_xml(options={})
    h = {}
    %w(data licence source source_url).each { |a| h[a.to_sym] = send(a) }
    h.to_xml(:skip_instruct => true, :root => name)
  end
  
end