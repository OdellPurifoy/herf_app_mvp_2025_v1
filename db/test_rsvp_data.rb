# Test data setup for RSVP functionality
puts 'Creating test data for RSVP functionality...'

# Create a lounge owner if one doesn't exist
lounge_owner = LoungeOwner.first_or_create!(
  email: 'test@example.com',
  password: 'password123',
  first_name: 'Test',
  last_name: 'Owner',
  date_of_birth: Date.new(1980, 1, 1)
)

puts "✅ Lounge Owner: #{lounge_owner.email}"

# Create a lounge if one doesn't exist
lounge = lounge_owner.lounges.first_or_create!(
  name: 'Test Cigar Lounge',
  address_street_1: '123 Main St',
  city: 'Test City',
  state: 'CA',
  zip_code: '12345',
  email: 'lounge@example.com',
  description: 'A test lounge for RSVP functionality'
)

puts "✅ Lounge: #{lounge.name}"

# Create some memberships if they don't exist
memberships = []
3.times do |i|
  membership = lounge.memberships.find_or_create_by(
    first_name: "Member#{i + 1}",
    last_name: 'Test',
    email: "member#{i + 1}@example.com",
    phone_number: "555-000-000#{i + 1}",
    active: true
  )
  memberships << membership
end

puts "✅ Created #{memberships.count} test memberships"

# Create a test event with RSVP needed
event = lounge.events.find_or_create_by(
  name: 'Test Wine Tasting Event'
) do |e|
  e.event_type = 'Wine Tasting'
  e.date = 1.week.from_now.to_date
  e.start_time = Time.parse('7:00 PM')
  e.end_time = Time.parse('9:00 PM')
  e.description = 'Join us for an exclusive wine tasting event featuring premium selections.'
  e.rsvp_needed = true
  e.capacity = 20
  e.members_only = true
end

puts "✅ Event: #{event.name} on #{event.date}"

# Create RSVPs for the memberships
rsvps = []
memberships.each do |membership|
  rsvp = Rsvp.find_or_create_by(
    event: event,
    membership: membership
  ) do |r|
    r.status = :pending
    r.guest_count = 1
  end
  rsvps << rsvp
end

puts "✅ Created #{rsvps.count} RSVPs"

# Display the RSVP tokens for testing
puts "\n🎯 RSVP Test Links:"
puts '=' * 50
rsvps.each do |rsvp|
  puts "#{rsvp.membership.member_name}: http://localhost:3000/rsvp/#{rsvp.rsvp_token}"
end

puts "\n📋 Test Instructions:"
puts '1. Start your Rails server: rails server'
puts '2. Visit any of the RSVP links above'
puts "3. Test responding with 'attending' and 'not attending'"
puts '4. Try different guest counts when attending'
puts '5. Check that expired RSVPs are handled properly'

puts "\n🔍 Console Commands to Check Results:"
puts 'Event.last.rsvps.attending.count  # Count attending'
puts 'Event.last.rsvps.not_attending.count  # Count not attending'
puts 'Event.last.total_confirmed_attendees  # Total guests attending'
puts 'Rsvp.last.status_display  # See status of last RSVP'
