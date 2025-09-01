# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/event_reminder_mailer
class EventReminderMailerPreview < ActionMailer::Preview
  def one_week_reminder
    EventReminderMailer.one_week_reminder(sample_event, sample_membership)
  end

  def one_week_reminder_with_rsvp
    EventReminderMailer.one_week_reminder(sample_rsvp_event, sample_membership_with_rsvp)
  end

  def one_day_reminder
    EventReminderMailer.one_day_reminder(sample_event, sample_membership)
  end

  def one_day_reminder_with_rsvp_pending
    EventReminderMailer.one_day_reminder(sample_rsvp_event, sample_membership_with_pending_rsvp)
  end

  def one_day_reminder_with_rsvp_attending
    EventReminderMailer.one_day_reminder(sample_rsvp_event, sample_membership_with_attending_rsvp)
  end

  private

  def sample_lounge
    @sample_lounge ||= Lounge.new(
      name: "The Gentleman's Den",
      email: 'info@gentlemansden.com',
      phone_number: '(555) 123-4567',
      address_street_1: '123 Cigar Lane, Smoke City, CA 90210'
    ).tap { |lounge| lounge.id = 1 }
  end

  def sample_membership
    @sample_membership ||= Membership.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com',
      phone_number: '(555) 987-6543',
      lounge: sample_lounge,
      active: :active,
      allow_email_notifications: true
    ).tap { |membership| membership.id = 1 }
  end

  def sample_membership_with_rsvp
    @sample_membership_with_rsvp ||= Membership.new(
      first_name: 'Jane',
      last_name: 'Smith',
      email: 'jane.smith@example.com',
      phone_number: '(555) 555-1234',
      lounge: sample_lounge,
      active: :active,
      allow_email_notifications: true
    ).tap { |membership| membership.id = 2 }
  end

  def sample_membership_with_pending_rsvp
    @sample_membership_with_pending_rsvp ||= Membership.new(
      first_name: 'Mike',
      last_name: 'Johnson',
      email: 'mike.johnson@example.com',
      phone_number: '(555) 444-3333',
      lounge: sample_lounge,
      active: :active,
      allow_email_notifications: true
    ).tap { |membership| membership.id = 3 }
  end

  def sample_membership_with_attending_rsvp
    @sample_membership_with_attending_rsvp ||= Membership.new(
      first_name: 'Sarah',
      last_name: 'Wilson',
      email: 'sarah.wilson@example.com',
      phone_number: '(555) 222-1111',
      lounge: sample_lounge,
      active: true,
      allow_email_notifications: true
    ).tap { |membership| membership.id = 4 }
  end

  def sample_event
    @sample_event ||= Event.new(
      name: 'Premium Cigar Tasting',
      event_type: 'Cigar Brand Event',
      date: 1.week.from_now.to_date,
      start_time: 1.week.from_now.change(hour: 19, min: 0),
      end_time: 1.week.from_now.change(hour: 22, min: 0),
      description: "Join us for an exclusive tasting featuring premium cigars from Cuba and Nicaragua. We'll be featuring rare vintage selections and expert-led discussions about flavor profiles and pairing recommendations.",
      lounge: sample_lounge,
      rsvp_needed: false,
      virtual: false,
      members_only: true,
      capacity: 25,
      entry_fee: 75.00
    ).tap { |event| event.id = 1 }
  end

  def sample_rsvp_event
    @sample_rsvp_event ||= Event.new(
      name: 'Annual Holiday Party',
      event_type: 'Holiday Party',
      date: 1.week.from_now.to_date,
      start_time: 1.week.from_now.change(hour: 18, min: 0),
      end_time: 1.week.from_now.change(hour: 23, min: 0),
      description: 'Celebrate the holidays with fellow members! Enjoy premium cigars, holiday cocktails, live jazz music, and a special dinner prepared by our chef. Dress code: cocktail attire.',
      lounge: sample_lounge,
      rsvp_needed: true,
      virtual: false,
      members_only: true,
      capacity: 50,
      entry_fee: 125.00
    ).tap { |event| event.id = 2 }
  end

  def sample_pending_rsvp
    @sample_pending_rsvp ||= Rsvp.new(
      event: sample_rsvp_event,
      membership: sample_membership_with_pending_rsvp,
      status: :pending,
      guest_count: 1,
      rsvp_token: SecureRandom.urlsafe_base64(32)
    ).tap do |rsvp|
      rsvp.id = 1
      # Mock the status_display method
      def rsvp.status_display
        'Pending Response'
      end

      # Mock the pending? method
      def rsvp.pending?
        true
      end
    end
  end

  def sample_attending_rsvp
    @sample_attending_rsvp ||= Rsvp.new(
      event: sample_rsvp_event,
      membership: sample_membership_with_attending_rsvp,
      status: :attending,
      guest_count: 2,
      rsvp_token: SecureRandom.urlsafe_base64(32)
    ).tap do |rsvp|
      rsvp.id = 2
      # Mock the status_display method
      def rsvp.status_display
        'Attending (2 guests)'
      end

      # Mock the pending? method
      def rsvp.pending?
        false
      end
    end
  end

  # Mock the rsvp_for_membership method on events
  def self.setup_event_rsvp_mocks
    # For events that need RSVP
    sample_rsvp_event = Event.new # This will be replaced by the actual method call

    def sample_rsvp_event.rsvp_for_membership(membership)
      case membership.id
      when 3
        # Pending RSVP
        @pending_rsvp ||= Rsvp.new(
          event: self,
          membership: membership,
          status: :pending,
          guest_count: 1,
          rsvp_token: SecureRandom.urlsafe_base64(32)
        ).tap do |rsvp|
          rsvp.define_singleton_method(:status_display) { 'Pending Response' }
          rsvp.define_singleton_method(:pending?) { true }
        end
      when 4
        # Attending RSVP
        @attending_rsvp ||= Rsvp.new(
          event: self,
          membership: membership,
          status: :attending,
          guest_count: 2,
          rsvp_token: SecureRandom.urlsafe_base64(32)
        ).tap do |rsvp|
          rsvp.define_singleton_method(:status_display) { 'Attending (2 guests)' }
          rsvp.define_singleton_method(:pending?) { false }
        end
      else
        # Default pending RSVP for other cases
        @rsvp_for_membership ||= Rsvp.new(
          event: self,
          membership: membership,
          status: :pending,
          guest_count: 1,
          rsvp_token: SecureRandom.urlsafe_base64(32)
        ).tap do |rsvp|
          rsvp.define_singleton_method(:status_display) { 'Pending Response' }
          rsvp.define_singleton_method(:pending?) { true }
        end
      end
    end
  end
end

# Setup the mocks when the class is loaded
EventReminderMailerPreview.setup_event_rsvp_mocks
