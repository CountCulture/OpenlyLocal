module GenericEntityMatcher
  extend self
  
  def possible_matches(params={})
    return unless entity_klass = params.delete(:type).try(:constantize)
    title_field = entity_klass.new.attribute_names.include?('title') ? 'title' : 'name'
    return unless results = 
      case 
      when entity_klass.respond_to?(:possible_matches)
        entity_klass.possible_matches(params)
      when entity_klass.new.respond_to?(:normalised_title)
        entity_klass.all(:conditions => ["normalised_title LIKE ?", "#{entity_klass.normalise_title(params[:title]).split.first}%"], :order => title_field)
      else
        entity_klass.all(:conditions => ["#{title_field} LIKE ?", "#{params[:title].split.first}%"], :order => title_field )
      end 
                                                            
    results.collect! do |res|
      MatchResult.new(:base_object => res, :match => (res.title == params[:title]) ) 
    end
    {:result => results}
  end
  
  class MatchResult
    attr_reader :match, :id, :score, :title, :type, :base_object
    def initialize(args={})
      if @base_object = args[:base_object]
        @id = @base_object.id
        @type = @base_object.class.to_s
        @title = @base_object.title
        @extended_title = @base_object.extended_title if @base_object.respond_to?(:extended_title)
        @score = args[:score]
        @match = args[:match]
      end
    end
    
    def extended_title
      @extended_title || @title
    end
    
  end
end