module CouncilsHelper
  def party_breakdown_graph(party_data)
    spare_colours = (3..13).collect { |i| "664422#{i.to_s(16).upcase*2}" } # iterate through numbers, turning them in to hex and adding to base colour
    parties, data = party_data.transpose
    colours = parties.collect{ |p| p.colour || spare_colours.shift } # use spare colours if no colour
    image_tag(Gchart.pie(:data => data, :legend => parties.collect(&:to_s), :size => "450x200", :bar_colors => colours), :class => "chart", :alt => "Party Breakdown Chart")
  end
  
  def open_data_link_for(council)
    return unless council.open_data_url?
    link_to("Open Data page", council.open_data_url, :class => "#{council.open_data_status} open_data_link", :title => council.open_data_licence_name||'Not explicitly licensed')
  end
end
