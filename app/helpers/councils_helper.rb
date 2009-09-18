module CouncilsHelper
  def party_breakdown_graph(party_data)
    spare_colours = (3..13).collect { |i| "664422#{i.to_s(16).upcase*2}" } # iterate through numbers, turning them in to hex and adding to base colour
    parties, data = party_data.transpose
    colours = parties.collect{ |p| p.colour || spare_colours.shift } # use spare colours if no colour
    image_tag(Gchart.pie(:data => data, :legend => parties.collect(&:to_s), :size => "450x200", :bar_colors => colours), :class => "chart", :alt => "Party Breakdown Chart")
  end
end
