module CouncilsHelper
  def party_breakdown_graph(party_data)
    legend, data = party_data.transpose
    image_tag(Gchart.pie(:data => data, :legend => legend, :size => "400x200"), :class => "chart")
  end
end
