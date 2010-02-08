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
  
  def party_in_control
    pb = party_breakdown
    return if pb.blank?
    total_seats = pb.sum{ |a| a[1] }
    main_party_info = pb.max{ |a,b| a[1] <=> b[1] }
    main_party_info[1] > total_seats/2 ? main_party_info.first : 'No Overall'
  end
  
end