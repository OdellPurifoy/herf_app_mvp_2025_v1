# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts '🌱 Seeding database...'

# Create a demo lounge owner
lounge_owner = LoungeOwner.find_or_create_by!(email: 'demo@cigarloungeapp.com') do |owner|
  owner.password = 'password123'
  owner.first_name = 'Demo'
  owner.last_name = 'Owner'
  owner.date_of_birth = Date.new(1980, 1, 1)
  owner.phone_number = '555-123-4567'
  puts "✅ Created demo lounge owner: #{owner.email}"
end

# Create a demo lounge
lounge = lounge_owner.lounges.find_or_create_by!(name: 'Demo Cigar Lounge') do |l|
  l.address_street_1 = '123 Main Street'
  l.city = 'Demo City'
  l.state = 'CA'
  l.zip_code = '90210'
  l.email = 'info@democigarlnounge.com'
  l.phone_number = '555-123-4567'
  l.description = 'A premium cigar lounge with an extensive selection of fine cigars and spirits.'
  l.alcohol_served = true
  l.food_served = true
  l.outside_cigars_allowed = false
  l.website = 'https://democigarlounge.com'
  puts "✅ Created demo lounge: #{l.name}"
end

# Create demo memberships
members_data = [
  { first_name: 'John', last_name: 'Smith', email: 'john.smith@example.com', phone: '555-001-0001' },
  { first_name: 'Sarah', last_name: 'Johnson', email: 'sarah.johnson@example.com', phone: '555-001-0002' },
  { first_name: 'Michael', last_name: 'Brown', email: 'michael.brown@example.com', phone: '555-001-0003' },
  { first_name: 'Emily', last_name: 'Davis', email: 'emily.davis@example.com', phone: '555-001-0004' },
  { first_name: 'David', last_name: 'Wilson', email: 'david.wilson@example.com', phone: '555-001-0005' },
  { first_name: 'Lisa', last_name: 'Martinez', email: 'lisa.martinez@example.com', phone: '555-001-0006' },
  { first_name: 'James', last_name: 'Anderson', email: 'james.anderson@example.com', phone: '555-001-0007' },
  { first_name: 'Maria', last_name: 'Garcia', email: 'maria.garcia@example.com', phone: '555-001-0008' }
]

memberships = []
members_data.each do |member_data|
  membership = lounge.memberships.find_or_create_by!(
    first_name: member_data[:first_name],
    last_name: member_data[:last_name]
  ) do |m|
    m.email = member_data[:email]
    m.phone_number = member_data[:phone]
    m.active = true
    m.allow_email_notifications = true
    m.allow_text_notifications = true
  end
  memberships << membership
end
puts "✅ Created #{memberships.count} demo memberships"

# Create demo events with and without RSVP
events_data = [
  {
    name: 'Weekend Wine & Cigar Pairing',
    event_type: 'Wine Tasting',
    date: 2.weeks.from_now.to_date,
    start_time: Time.parse('7:00 PM'),
    end_time: Time.parse('9:30 PM'),
    description: 'Join us for an exclusive wine and cigar pairing experience featuring premium selections from our cellar.',
    rsvp_needed: true,
    capacity: 20,
    members_only: true,
    entry_fee: '$75'
  },
  {
    name: 'Monthly Poker Night',
    event_type: 'Other',
    date: 3.weeks.from_now.to_date,
    start_time: Time.parse('8:00 PM'),
    end_time: Time.parse('11:00 PM'),
    description: 'Monthly poker tournament with cigars and drinks. Buy-in is $50 with prizes for top 3 finishers.',
    rsvp_needed: true,
    capacity: 12,
    members_only: true,
    entry_fee: '$50'
  },
  {
    name: 'Whiskey Wednesday',
    event_type: 'Whiskey Tasting',
    date: 1.week.from_now.to_date,
    start_time: Time.parse('6:30 PM'),
    end_time: Time.parse('8:30 PM'),
    description: 'Weekly whiskey tasting featuring different distilleries and regions. This week: Scottish Highlands.',
    rsvp_needed: false,
    members_only: false,
    entry_fee: '$45'
  },
  {
    name: 'New Year Celebration',
    event_type: 'Holiday Party',
    date: 1.month.from_now.to_date,
    start_time: Time.parse('9:00 PM'),
    end_time: Time.parse('1:00 AM'),
    description: 'Ring in the New Year with premium cigars, champagne, and live jazz music.',
    rsvp_needed: true,
    capacity: 50,
    members_only: false,
    entry_fee: '$150'
  }
]

events = []
events_data.each do |event_data|
  event = lounge.events.find_or_create_by!(
    name: event_data[:name],
    date: event_data[:date]
  ) do |e|
    e.event_type = event_data[:event_type]
    e.start_time = event_data[:start_time]
    e.end_time = event_data[:end_time]
    e.description = event_data[:description]
    e.rsvp_needed = event_data[:rsvp_needed]
    e.capacity = event_data[:capacity]
    e.members_only = event_data[:members_only]
    e.entry_fee = event_data[:entry_fee]
  end
  events << event
  puts "✅ Created event: #{event.name} (RSVP needed: #{event.rsvp_needed?})"
end

# Show RSVP creation results
rsvp_events = events.select(&:rsvp_needed?)
total_rsvps = rsvp_events.sum { |event| event.rsvps.count }
puts "✅ Automatically created #{total_rsvps} RSVPs across #{rsvp_events.count} events"

# Create some sample RSVP responses for demonstration
if total_rsvps.positive?
  puts "\n📝 Creating sample RSVP responses..."

  rsvp_events.each do |event|
    event.rsvps.limit(3).each_with_index do |rsvp, index|
      case index
      when 0
        rsvp.update!(status: :attending, guest_count: 2)
        puts "   ✅ #{rsvp.member_name} attending #{event.name} with 2 guests"
      when 1
        rsvp.update!(status: :declined)
        puts "   ❌ #{rsvp.member_name} declined #{event.name}"
      when 2
        rsvp.update!(status: :attending, guest_count: 1)
        puts "   ✅ #{rsvp.member_name} attending #{event.name} with 1 guest"
      end
    end
  end
end

# Create some special offers
special_offers_data = [
  {
    name: 'Member Monday Discount',
    offer_type: 'Discount',
    start_date: Date.current,
    end_date: 3.months.from_now.to_date,
    description: '20% off all cigars for members every Monday',
    members_only: true,
    offer_code: 'MONDAY20'
  },
  {
    name: 'Happy Hour Special',
    offer_type: 'Discount',
    start_date: Date.current,
    end_date: 1.month.from_now.to_date,
    description: 'Buy 2 drinks, get 1 free during happy hour (5-7 PM)',
    members_only: false,
    offer_code: 'HAPPY2FOR1'
  }
]

special_offers_data.each do |offer_data|
  offer = lounge.special_offers.find_or_create_by!(
    name: offer_data[:name]
  ) do |o|
    o.offer_type = offer_data[:offer_type]
    o.start_date = offer_data[:start_date]
    o.end_date = offer_data[:end_date]
    o.description = offer_data[:description]
    o.members_only = offer_data[:members_only]
    o.offer_code = offer_data[:offer_code]
  end
  puts "✅ Created special offer: #{offer.name}"
end

puts "\n🎯 Sample RSVP URLs for testing:"
puts '=' * 50
if total_rsvps.positive?
  Event.joins(:rsvps).where(rsvp_needed: true).first.rsvps.limit(3).each do |rsvp|
    puts "#{rsvp.member_name}: http://localhost:3000/rsvp/#{rsvp.rsvp_token}"
  end
end

puts "\n🎉 Database seeded successfully!"
puts '📊 Created:'
puts '   - 1 demo lounge owner (demo@cigarloungeapp.com / password123)'
puts '   - 1 demo lounge'
puts "   - #{memberships.count} memberships"
puts "   - #{events.count} events (#{rsvp_events.count} with RSVP)"
puts "   - #{total_rsvps} RSVPs"
puts '   - 2 special offers'
puts "\n💻 To test the application:"
puts '   1. rails server'
puts '   2. Visit http://localhost:3000'
puts '   3. Login with demo@cigarloungeapp.com / password123'
puts '   4. Test RSVP URLs above'
