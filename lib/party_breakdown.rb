module PartyBreakdown
  
  def party_breakdown
    party_groups = members.group_by{ |m| m.party.to_s }
    return [] if party_groups.size==1 && (party_groups[nil]||party_groups[""]) # i.e. members but no parties
    if party_groups[nil]||party_groups[""]
      party_groups["Not known"] = party_groups[nil].to_a + party_groups[""].to_a
      party_groups.delete(nil)
      party_groups.delete("") # replace nil or blank keys with 'Not known'
    end
    party_groups.collect{|k,v| [Party.new(k), v.size]}.sort{ |x,y| y[1] <=> x[1]  }
  end
  
end