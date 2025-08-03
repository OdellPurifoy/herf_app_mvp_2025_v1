# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RsvpNotificationMailer, type: :mailer do
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:membership) { FactoryBot.create(:membership, lounge: lounge) }
  let(:event) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 1.week.from_now.to_date,
                      start_time: Time.zone.today + 1.week + 7.hours,
                      end_time: Time.zone.today + 1.week + 9.hours,
                      rsvp_needed: true)
  end
  let(:rsvp) { FactoryBot.create(:rsvp, event: event, membership: membership) }

  describe 'rsvp_invitation' do
    let(:mail) { RsvpNotificationMailer.with(rsvp: rsvp).rsvp_invitation }

    it 'renders the headers' do
      expect(mail.subject).to include('RSVP Required')
      expect(mail.subject).to include(event.name)
      expect(mail.to).to eq([membership.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(membership.first_name)
      expect(mail.body.encoded).to include(event.name)
      expect(mail.body.encoded).to include(lounge.name)
      expect(mail.body.encoded).to include('RSVP Now')
    end

    it 'includes the RSVP URL' do
      expect(mail.body.encoded).to include(rsvp.rsvp_token)
    end
  end
end
