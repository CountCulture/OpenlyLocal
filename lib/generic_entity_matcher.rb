module GenericEntityMatcher
  extend self
  
  def possible_matches(params={})
    return unless entity_klass = params.delete(:entity_type)
    entity_klass.constantize.possible_matches(params)
  end
end