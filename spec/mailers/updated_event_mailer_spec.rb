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
      expect(mail.body.encoded).to match('UPDATED DATE:') if changed_attributes.include?(:date)
      expect(mail.body.encoded).to match(event.date.strftime('%A, %B %d, %Y')) if changed_attributes.include?(:date)
      expect(mail.body.encoded).to match('UPDATED TIME:') if changed_attributes.include?(:start_time)
      if changed_attributes.include?(:start_time)
        expect(mail.body.encoded).to match(event.start_time.strftime('%I:%M %p'))
      end
      expect(mail.body.encoded).to match(event.end_time.strftime('%I:%M %p')) if changed_attributes.include?(:end_time)
      expect(mail.body.encoded).to match('UPDATED DESCRIPTION:') if changed_attributes.include?(:description)
      expect(mail.body.encoded).to match(event.description) if changed_attributes.include?(:description)
    end
  end
end
