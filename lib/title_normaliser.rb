module TitleNormaliser

  extend self

  def normalise_title(raw_title)
    return unless raw_title
    raw_title.gsub('&', ' and ').gsub(/-/im, ' ').gsub(/\.\s/im, ' ').gsub(/-|\:|\'|\(|\)|\"|the /im, '').downcase.squish 
  end
  
  def normalise_company_title(raw_title)
    return unless raw_title
    semi_normed_title = raw_title.gsub(/\bT\/A\b.+/i, '').gsub(/\./,'').sub(/ltd/i, 'limited').sub(/public limited company/i, 'plc')
    normalise_title(semi_normed_title).downcase
  end
  
  def normalise_financial_sum(raw_value)
    if raw_value.is_a?(String)
      cleaned_up_value = raw_value.gsub(/[^\d\.\-\(\)]/,'')
      cleaned_up_value.match(/^\(([\d\.]+)\)$/) ? "-#{$1}" : cleaned_up_value
    else
      raw_value
    end
  end
  
  def normalise_url(raw_url)
    return if raw_url.blank?
    raw_url.match(/(http:\/\/|https:\/\/)+/) ? raw_url.sub(/(^.+http)+/, 'http').gsub(/(http:\/\/|https:\/\/)+/, '\1') : "http://#{raw_url}"
  end
  
  module Base
    module ClassMethods
      def normalise_title(raw_title)
        TitleNormaliser.normalise_title(raw_title)
      end

    end
    
    module InstanceMethods
  
      private
      def normalise_title
        self.normalised_title = self.class.normalise_title(title)
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.before_save :normalise_title
    end
  end
  
end
