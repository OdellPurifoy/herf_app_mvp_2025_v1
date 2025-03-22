# Preview all emails at http://localhost:3000/rails/mailers/new_event_mailer
class NewEventMailerPreview < ActionMailer::Preview
  def notify
    member = LoungeOwner.first
    event = Event.first
    NewEventMailer.with(member: member, event: event).notify
  end
end
