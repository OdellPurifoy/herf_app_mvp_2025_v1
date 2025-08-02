#!/usr/bin/env ruby

# Quick test script to verify RSVP functionality
# Run with: rails runner test_rsvp_functionality.rb

puts '🧪 Testing RSVP Functionality'
puts '=' * 40

# Test the RSVP model
puts "\n1. Testing RSVP Model..."

# Check if we have any RSVPs
rsvp_count = Rsvp.count
puts "Total RSVPs in database: #{rsvp_count}"

if rsvp_count == 0
  puts '❌ No RSVPs found. Run db/test_rsvp_data.rb first to create test data.'
  exit
end

# Get a sample RSVP
sample_rsvp = Rsvp.first
puts "✅ Sample RSVP found: #{sample_rsvp.rsvp_token[0..8]}..."

# Test RSVP token lookup
found_rsvp = Rsvp.find_by_token(sample_rsvp.rsvp_token)
puts "✅ Token lookup works: #{found_rsvp.present?}"

# Test RSVP status enum
puts "✅ Initial status: #{sample_rsvp.status}"
puts "✅ Status display: #{sample_rsvp.status_display}"

# Test member and event associations
puts "✅ Member: #{sample_rsvp.member_name}"
puts "✅ Event: #{sample_rsvp.event_title}"

# Test expiration check
puts "✅ Valid for response: #{sample_rsvp.valid_for_response?}"
puts "✅ Expires at: #{sample_rsvp.expires_at}"

# Test responding to RSVP
puts "\n2. Testing RSVP Response..."
if sample_rsvp.respond_with('attending', 2)
  puts '✅ Successfully updated RSVP to attending with 2 guests'
  puts "✅ New status: #{sample_rsvp.reload.status_display}"
else
  puts '❌ Failed to update RSVP'
end

# Test event RSVP aggregation
event = sample_rsvp.event
puts "\n3. Testing Event RSVP Aggregation..."
puts "✅ Total confirmed attendees: #{event.total_confirmed_attendees}"
puts "✅ Pending RSVPs: #{event.pending_rsvps_count}"
puts "✅ Attending RSVPs: #{event.attending_rsvps_count}"

# Generate test URLs
puts "\n4. Test RSVP URLs:"
puts '=' * 40
Rsvp.limit(3).each do |rsvp|
  puts "#{rsvp.member_name}: http://localhost:3000/rsvp/#{rsvp.rsvp_token}"
end

puts "\n🎯 Next Steps:"
puts '1. Start Rails server: rails server'
puts '2. Visit the URLs above to test the RSVP form'
puts "3. Try both 'attending' and 'not attending' responses"
puts '4. Test different guest counts'

puts "\n✅ RSVP functionality test completed!"
