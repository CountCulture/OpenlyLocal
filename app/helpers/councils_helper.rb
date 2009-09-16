module CouncilsHelper
  def party_breakdown_graph(party_data)
    spare_colours = ["664422CC", "664422AA", "66442277", "66442233"]
    parties, data = party_data.transpose
    colours = parties.collect{ |p| p.colour || spare_colours.shift } # use spare colours if no colour
    image_tag(Gchart.pie(:data => data, :legend => parties.collect(&:to_s), :size => "450x200", :bar_colors => colours), :class => "chart", :alt => "Party Breakdown Chart")
  end
end
