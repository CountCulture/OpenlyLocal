# require 'soap'
require 'soap/rpc/driver'
require 'soap/wsdlDriver'
# require 'wsse_authentication.rb'
require 'soap/header/simplehandler'
# require 'wsse_authentication.rb'
module NessUtilities

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
    attr_reader :request_method, :params
    def initialize(req_meth, req_params={})
      @request_method = req_meth
      @params = req_params
      if params.delete(:service).to_s=='delivery'
        @ness_service, @ness_ns, @ns_path = 'deliveryservice', 'del', '/interop/NeSSDeliveryBindingPort'
      else
        @ness_service, @ness_ns, @ns_path = 'discoverystructs', 'dis', '/interop/NeSSDiscoveryBindingPort'
      end
    end

    def process
      req_data = build_request
      Nokogiri.XML(_http_get(req_data))
    end

    def process_and_extract_datapoints
      extract_datapoints(process)
    end

    protected
    def _http_get(req_data)
      return if RAILS_ENV=='test' # don't make calls in test env
      http = Net::HTTP.new('www.neighbourhood.statistics.gov.uk', 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      headers = {'Content-Type' => 'text/xml'}
      resp, data = http.post(@ns_path, req_data, headers)
      data
    end

    def extract_datapoints(resp=nil)
    return if resp.blank?
      res = []
      resp.search('lgdx|Dataset', 'lgdx' => "http://schema.esd.org.uk/LGDX").each do |dataset|
        topics = dataset.search('lgdx|Topic', 'lgdx' => "http://schema.esd.org.uk/LGDX")
        datapoints = dataset.search('lgdx|DatasetItem', 'lgdx' => "http://schema.esd.org.uk/LGDX")

        topics.each_with_index do |topic, i|
          topic_id = topics[i].at('lgdx|TopicCode', 'lgdx' => "http://schema.esd.org.uk/LGDX").inner_text
          value = datapoints[i].at('lgdx|Value', 'lgdx' => "http://schema.esd.org.uk/LGDX").inner_text
          res << { :ons_dataset_topic_id => topic_id,
                   :value => value } # pair up topics and datapoints
        end
      end
      res
    end

    def build_request
      xml = Builder::XmlMarkup.new(:indent => 2, :margin => 3 )
      req_body = xml.tag!("#{@ness_ns}:#{request_method}Element") do
        params.each do |key, value|
          xml.tag!(key, value)
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
