module GenericEntityMatcher
  extend self
  
  def possible_matches(params={})
    return unless entity_klass = params.delete(:entity_type).try(:constantize)
    title_field = entity_klass.new.attribute_names.include?('title') ? 'title' : 'name'
    entity_klass.respond_to?(:possible_matches) ? entity_klass.possible_matches(params) : 
                                                  entity_klass.all(:conditions => ["#{title_field} LIKE ?", "#{params[:title].split.first}%"] )
  end
end