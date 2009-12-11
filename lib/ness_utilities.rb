# require 'soap'
require 'soap/rpc/driver'
require 'soap/wsdlDriver'
# require 'wsse_authentication.rb'
require 'soap/header/simplehandler'
# require 'wsse_authentication.rb'
module NessUtilities
  Muids = { 1 => ['Count'],
            2 => ['Percentage', "%.1f%"],
            9 => ['Pounds Sterling', "£%d"]}

  class DiscoveryClient < ::SOAP::RPC::Driver
    Endpoint = "https://www.neighbourhood.statistics.gov.uk/interop/NeSSDiscoveryBindingPort?WSDL"
    MappingRegistry = ::SOAP::Mapping::Registry.new

    def self.driver
      @@driver = SOAP::WSDLDriverFactory.new(Endpoint).create_rpc_driver
      @@driver.headerhandler << WsseAuthHeader.new()
      @@driver
    end

    def initialize(endpoint_url = nil)
      # endpoint_url ||= DefaultEndpointUrl
      # super(endpoint_url, nil)
      # self.mapping_registry = MappingRegistry
      # init_methods
    end

  end

  class RawClient
    # class RequestError < Standard Error;end
    attr_reader :request_method, :params, :ness_ns, :ness_service, :ns_path

    def initialize(req_meth, params_array=[])
      @request_method = req_meth
      @params = params_array
      @ness_service, @ness_ns, @ns_path = 'discoverystructs', 'dis', '/interop/NeSSDiscoveryBindingPort'
    end

    def process(extra_options=[])
      req_data = build_request(extra_options)
      Nokogiri.XML(_http_post(req_data))
    end

    def process_and_extract_datapoints
      self.service = 'delivery'
      extract_datapoints(process([['GroupByDataset', 'No']]))
    end

    # set service to 'delivery' to change namespact, endpoints etc
    def service=(serv_name)
      if serv_name.to_s == 'delivery'
        @ness_service, @ness_ns, @ns_path = 'deliveryservice', 'del', '/interop/NeSSDeliveryBindingPort'
      end
    end

    protected
    def _http_post(req_data)
      return if RAILS_ENV=='test' # don't make calls in test env
      http = Net::HTTP.new('www.neighbourhood.statistics.gov.uk', 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      headers = {'Content-Type' => 'text/xml'}
      RAILS_DEFAULT_LOGGER.debug {"***Submitting SOAP request to Ness:\n#{req_data}"}
      resp, data = http.post(@ns_path, req_data, headers)
      RAILS_DEFAULT_LOGGER.debug {"*** SOAP response from Ness:\n#{data}"}
      data
    end

    def extract_datapoints(resp=nil)
    return if resp.blank?
      res = []
      raw_datapoints = resp.search('lgdx|DatasetItem', 'lgdx' => "http://schema.esd.org.uk/LGDX").collect { |d| {:value => lgdx_attrib('Value', d), :topic_id => lgdx_attrib('TopicId', d), :area_id => lgdx_attrib('BoundaryId', d)} }
      topics = resp.search('lgdx|Topic', 'lgdx' => "http://schema.esd.org.uk/LGDX").collect { |t| {:id => lgdx_attrib('TopicId', t), :ness_topic_id => lgdx_attrib('TopicCode', t)} }
      areas = resp.search('lgdx|Boundary', 'lgdx' => "http://schema.esd.org.uk/LGDX").collect { |a| {:id => lgdx_attrib('BoundaryId', a), :ness_area_id => lgdx_attrib('Identifier', a)} }

      # merge datapoints with ness topic and area ids, replacing response ids
      raw_datapoints.collect do |dp|
        { :value => dp[:value],
          :ness_topic_id => topics.detect{|t| t[:id] == dp[:topic_id]}[:ness_topic_id],
          :ness_area_id => areas.detect{|a| a[:id] == dp[:area_id]}[:ness_area_id]
          }
      end
    end

    def build_request(extra_terms=[])
      xml = Builder::XmlMarkup.new(:indent => 2, :margin => 3 )
      req_body = xml.tag!("#{@ness_ns}:#{request_method}Element") do
        (params+extra_terms).each do |key, value|
          xml.tag!("#{@ness_ns}:#{key}", (value.kind_of?(Array) ? value.join(',') : value))
        end
      end

      req = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:#{@ness_ns}="http://neighbourhood.statistics.gov.uk/nde/v1-0/#{@ness_service}">
   <soapenv:Header><wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><wsse:UsernameToken wsu:Id="UsernameToken-9" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wsse:Username>#{NESS_USERNAME}</wsse:Username><wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">#{NESS_PASSWORD}</wsse:Password></wsse:UsernameToken></wsse:Security></soapenv:Header>
   <soapenv:Body>
#{req_body}   </soapenv:Body>
</soapenv:Envelope>
EOF

    end

    def lgdx_attrib(key, obj)
      obj.at("lgdx|#{key}", 'lgdx' => "http://schema.esd.org.uk/LGDX").inner_text
    end
  end


  class WsseAuthHeader < SOAP::Header::SimpleHandler
    NAMESPACE = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'

    def initialize()
      super(XSD::QName.new(NAMESPACE, 'Security'))
    end

    def on_simple_outbound
      {"UsernameToken" => {"Username" => NESS_USERNAME, "Password" => NESS_PASSWORD}}
    end
  end
end
