# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CancelledEventMailer, type: :mailer do
  include ApplicationHelper

  describe 'notify' do
    let(:member) { FactoryBot.create(:membership) }
    let(:event) { FactoryBot.create(:event) }
    let(:mail) { CancelledEventMailer.with(member: member, event: event).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Event Cancelled: #{event.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['info@herfapp.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Important Update, #{member.first_name}!")
      expect(mail.body.encoded).to match(event.name)
      expect(mail.body.encoded).to match(event.date.strftime('%A, %B %d, %Y'))
      expect(mail.body.encoded).to match(event.start_time.strftime('%I:%M %p'))
      expect(mail.body.encoded).to match('Event Cancellation')
      expect(mail.body.encoded).to match('Cancellation Notice')
      expect(mail.body.encoded).to match('has been cancelled')
      expect(mail.body.encoded).to match(event.lounge.email)
      expect(mail.body.encoded).to match('Powered by Herf')
    end
  end
end
