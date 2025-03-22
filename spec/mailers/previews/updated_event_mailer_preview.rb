# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/updated_event_mailer
class UpdatedEventMailerPreview < ActionMailer::Preview
  def notify
    member = LoungeOwner.first
    event = Event.first
    UpdatedEventMailer.with(member: member, event: event).notify
  end
end
