# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpecialOfferUpdateNotificationJob, type: :job do
  describe '#perform' do
    let(:lounge) { FactoryBot.create(:lounge) }
    let(:special_offer) { FactoryBot.create(:special_offer, lounge: lounge) }
    let!(:member1) do
      FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: true, opt_out_text_messaging: false,
                                     active: true)
    end
    let!(:member2) { FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: false, active: true) }
    let!(:member3) do
      FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: true, opt_out_text_messaging: true,
                                     active: true)
    end
    let!(:inactive_member) do
      FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: true, opt_out_text_messaging: false,
                                     active: false)
    end
    let(:sms_service) { instance_double(SmsNotificationService) }

    before do
      allow(SpecialOffer).to receive(:find).with(special_offer.id).and_return(special_offer)
      allow(SmsNotificationService).to receive(:new).and_return(sms_service)
      allow(sms_service).to receive(:send_message)
    end

    it 'enqueues the job' do
      expect do
        SpecialOfferUpdateNotificationJob.perform_later(special_offer.id)
      end.to have_enqueued_job(SpecialOfferUpdateNotificationJob).with(special_offer.id)
    end

    it 'sends notifications to active members who allow text notifications and have not opted out' do
      expect(SmsNotificationService).to receive(:new).with(
        to: member1.phone_number,
        body: instance_of(String)
      ).and_return(sms_service)
      expect(sms_service).to receive(:send_message)

      SpecialOfferUpdateNotificationJob.perform_now(special_offer.id)
    end

    it 'does not send notifications to members who do not allow text notifications' do
      expect(SmsNotificationService).not_to receive(:new).with(
        hash_including(to: member2.phone_number)
      )

      SpecialOfferUpdateNotificationJob.perform_now(special_offer.id)
    end

    it 'does not send notifications to members who have opted out of text messaging' do
      expect(SmsNotificationService).not_to receive(:new).with(
        hash_including(to: member3.phone_number)
      )

      SpecialOfferUpdateNotificationJob.perform_now(special_offer.id)
    end

    it 'does not send notifications to inactive members' do
      expect(SmsNotificationService).not_to receive(:new).with(
        hash_including(to: inactive_member.phone_number)
      )

      SpecialOfferUpdateNotificationJob.perform_now(special_offer.id)
    end

    it 'returns message when special offer is not found' do
      allow(SpecialOffer).to receive(:find).with(999).and_raise(ActiveRecord::RecordNotFound)
      expect(SpecialOfferUpdateNotificationJob.perform_now(999)).to be_nil
    end

    it 'returns message when no active members are found' do
      empty_lounge = FactoryBot.create(:lounge)
      empty_special_offer = FactoryBot.create(:special_offer, lounge: empty_lounge)
      allow(SpecialOffer).to receive(:find).with(empty_special_offer.id).and_return(empty_special_offer)

      expect(SpecialOfferUpdateNotificationJob.perform_now(empty_special_offer.id)).to eq('No active members found for the lounge')
    end

    it 'includes update information in the notification message' do
      expect(SmsNotificationService).to receive(:new).with(
        to: member1.phone_number,
        body: /has updated a special offer for you!/i
      ).and_return(sms_service)

      SpecialOfferUpdateNotificationJob.perform_now(special_offer.id)
    end
  end
end
