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
    # Methods = [
    #   ["hello_world", "hello_world",
    #     [
    #       [:in, "from", [::SOAP::SOAPString]],
    #       [:retval, "from", [::SOAP::SOAPString]]
    #     ],
    #     "http://localhost:2000/wsdl/hws.wsdl#hello_world", "http://localhost:2000/wsdl/hws.wsdl", :rpc
    #   ]
    # ]

    def initialize(endpoint_url = nil)
      # endpoint_url ||= DefaultEndpointUrl
      # super(endpoint_url, nil)
      # self.mapping_registry = MappingRegistry
      # init_methods
    end

  private

    # def init_methods
    #   Methods.each do |name_as, name, params, soapaction, namespace, style|
    #     qname = XSD::QName.new(namespace, name_as)
    #     if style == :document
    #       @proxy.add_document_method(soapaction, name, params)
    #       add_document_method_interface(name, params)
    #     else
    #       @proxy.add_rpc_method(qname, soapaction, name, params)
    #       add_rpc_method_interface(name, params)
    #     end
    #     if name_as != name and name_as.capitalize == name.capitalize
    #       sclass = class << self; self; end
    #       sclass.__send__(:define_method, name_as, proc { |*arg|
    #         __send__(name, *arg)
    #       })
    #     end
    #   end
    # end
  end

  class DeliveryClient < ::SOAP::RPC::Driver
    Endpoint = "https://www.neighbourhood.statistics.gov.uk/interop/NeSSDeliveryBindingPort?WSDL"
    MappingRegistry = ::SOAP::Mapping::Registry.new

    def self.driver
      @@driver = SOAP::WSDLDriverFactory.new(Endpoint).create_rpc_driver
      @@driver.headerhandler << WsseAuthHeader.new()
      @@driver
    end
    # Methods = [
    #   ["hello_world", "hello_world",
    #     [
    #       [:in, "from", [::SOAP::SOAPString]],
    #       [:retval, "from", [::SOAP::SOAPString]]
    #     ],
    #     "http://localhost:2000/wsdl/hws.wsdl#hello_world", "http://localhost:2000/wsdl/hws.wsdl", :rpc
    #   ]
    # ]

    def initialize(endpoint_url = nil)
      # endpoint_url ||= DefaultEndpointUrl
      # super(endpoint_url, nil)
      # self.mapping_registry = MappingRegistry
      # init_methods
    end

  private

    # def init_methods
    #   Methods.each do |name_as, name, params, soapaction, namespace, style|
    #     qname = XSD::QName.new(namespace, name_as)
    #     if style == :document
    #       @proxy.add_document_method(soapaction, name, params)
    #       add_document_method_interface(name, params)
    #     else
    #       @proxy.add_rpc_method(qname, soapaction, name, params)
    #       add_rpc_method_interface(name, params)
    #     end
    #     if name_as != name and name_as.capitalize == name.capitalize
    #       sclass = class << self; self; end
    #       sclass.__send__(:define_method, name_as, proc { |*arg|
    #         __send__(name, *arg)
    #       })
    #     end
    #   end
    # end
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
