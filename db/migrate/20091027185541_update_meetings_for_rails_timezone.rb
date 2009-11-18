class UpdateMeetingsForRailsTimezone < ActiveRecord::Migration
  def self.up
    Meeting.all.each do |meeting|
      meeting.update_attribute(:date_held, meeting.date_held.to_s(:db))
    end
  end

  def self.down
  end
end
