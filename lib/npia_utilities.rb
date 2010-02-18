module NpiaUtilities
  
  class Client
    BaseUrl = 'http://policeapi.rkh.co.uk/'
    
    attr_reader :request_method, :params
    
    def initialize(request_method, params={})
      @request_method = request_method
      @params = params
    end
    
    def response
      raw_resp = _http_get(request_url)
      Crack::XML.parse(raw_resp)["police_api"]["response"]
    end
    
    def request_url
      BaseUrl + request_method.to_s.dasherize + "?key=#{NPIA_API_KEY}" + convert_to_query_params(params)
    end
    
    protected
    def _http_get(url)
      return if RAILS_ENV=='test'
      open(url).read
    end
    
    def convert_to_query_params(h_params)
      "&" + h_params.collect do |k,v|
        "#{k.to_s.dasherize}=#{v}"
      end.join('&')
    end
  end
end