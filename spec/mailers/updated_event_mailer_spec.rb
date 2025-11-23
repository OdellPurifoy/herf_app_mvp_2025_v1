# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatedEventMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.build(:membership) }
    let(:event) { FactoryBot.build(:event) }
    let(:changed_attributes) { %i[date start_time end_time description] }
    let(:mail) { UpdatedEventMailer.with(member: member, event: event, changed_attributes: changed_attributes).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Event Update: #{event.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Hi #{member.first_name}!")
      expect(mail.body.encoded).to match(event.name)
      expect(mail.body.encoded).to match(event.date.strftime('%A, %B %d, %Y'))
      expect(mail.body.encoded).to match(event.start_time.strftime('%I:%M %p'))
      expect(mail.body.encoded).to match(event.end_time.strftime('%I:%M %p'))
      expect(mail.body.encoded).to match('Powered by Herf')
    end
  end
end
