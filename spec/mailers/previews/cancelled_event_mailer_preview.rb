# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/cancelled_event_mailer
class CancelledEventMailerPreview < ActionMailer::Preview
  def notify
    member = LoungeOwner.first
    event = Event.first
    CancelledEventMailer.with(member: member, event: event).notify
  end
end
