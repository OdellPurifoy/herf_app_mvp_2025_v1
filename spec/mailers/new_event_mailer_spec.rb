require 'rails_helper'

RSpec.describe NewEventMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.create(:membership) }
    let(:event) { FactoryBot.create(:event) }
    let(:mail) { NewEventMailer.with(member: member, event: event).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("New Event: #{event.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Join us, #{member.first_name}!")
      expect(mail.body.encoded).to match(event.name)
      expect(mail.body.encoded).to match('<strong>Event Description:</strong>')
      expect(mail.body.encoded).to match(event.description)
    end
  end
end
