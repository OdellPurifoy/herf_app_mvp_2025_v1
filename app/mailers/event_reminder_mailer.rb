# frozen_string_literal: true

class EventReminderMailer < ApplicationMailer
  def one_week_reminder(event, membership)
    @event = event
    @membership = membership
    @lounge = event.lounge
    @rsvp = event.rsvp_for_membership(membership) if event.rsvp_needed?

    mail(
      to: membership.email,
      subject: "Reminder: #{@event.name} is coming up next week!"
    )
  end

  def one_day_reminder(event, membership)
    @event = event
    @membership = membership
    @lounge = event.lounge
    @rsvp = event.rsvp_for_membership(membership) if event.rsvp_needed?

    mail(
      to: membership.email,
      subject: "Tomorrow: #{@event.name} at #{@lounge.name}",
      template_name: 'one_day_reminder'
    )
  end
end
