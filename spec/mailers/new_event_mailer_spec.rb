# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewEventMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.build(:membership) }
    let(:event) { FactoryBot.build(:event) }
    let(:mail) { NewEventMailer.with(member: member, event: event).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("New Event: #{event.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Hi #{member.first_name}!")
      expect(mail.body.encoded).to match(event.name)
      expect(mail.body.encoded).to match('EVENT DETAILS:')
      expect(mail.body.encoded).to match(event.description)
    end
  end
end
