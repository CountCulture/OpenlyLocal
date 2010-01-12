module HyperlocalSitesHelper
  def distance_of(site)
    return unless site.respond_to?(:distance)&&!site.distance.blank?
    content_tag(:span, "#{number_with_precision(site.distance, :precision => 1)} miles", :class => "distance")
  end
end
