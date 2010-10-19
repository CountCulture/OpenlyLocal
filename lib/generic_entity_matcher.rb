module GenericEntityMatcher
  extend self
  
  def possible_matches(params={})
    return unless entity_klass = params.delete(:type).try(:constantize)
    title_field = entity_klass.new.attribute_names.include?('title') ? 'title' : 'name'
    return unless results = entity_klass.respond_to?(:possible_matches) ? entity_klass.possible_matches(params) : 
                                                            entity_klass.all(:conditions => ["#{title_field} LIKE ?", "#{params[:title].split.first}%"] )
    results.collect! do |res|
      MatchResult.new(:base_object => res, :match => (res.title == params[:title]) ) 
    end
    {:result => results}
  end
  
  class MatchResult
    attr_reader :match, :id, :score, :name, :type, :base_object
    def initialize(args={})
      if @base_object = args[:base_object]
        @id = @base_object.id
        @type = @base_object.class.to_s
        @name = @base_object.title
        @score = args[:score]
        @match = args[:match]
      end
    end
    
    
  end
end