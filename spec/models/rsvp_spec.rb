# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rsvp, type: :model do
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

  describe 'factory' do
    it 'has a valid factory' do
      rsvp = FactoryBot.build(:rsvp, event: event, membership: membership)
      expect(rsvp).to be_valid
    end
  end

  describe 'ActiveRecord associations' do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:membership) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:rsvp, event: event, membership: membership) }

    it { is_expected.to validate_presence_of(:guest_count) }
    it { is_expected.to validate_uniqueness_of(:rsvp_token) }
    it { is_expected.to validate_numericality_of(:guest_count).is_greater_than(0).is_less_than_or_equal_to(10) }

    describe 'unique RSVP per event per membership' do
      it 'validates uniqueness of event_id scoped to membership_id' do
        FactoryBot.create(:rsvp, event: event, membership: membership)
        duplicate_rsvp = FactoryBot.build(:rsvp, event: event, membership: membership)

        expect(duplicate_rsvp).not_to be_valid
        expect(duplicate_rsvp.errors[:event_id]).to include('can only have one RSVP per event')
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, attending: 1, declined: 2, expired: 3) }
  end

  describe 'scopes' do
    let!(:valid_rsvp) { FactoryBot.create(:rsvp, event: event, membership: membership, expires_at: 1.day.from_now) }
    let!(:expired_rsvp) do
      FactoryBot.create(:rsvp, :expired, event: event, membership: FactoryBot.create(:membership, lounge: lounge))
    end

    describe '.valid' do
      it 'returns RSVPs that have not expired' do
        expect(Rsvp.valid).to include(valid_rsvp)
        expect(Rsvp.valid).not_to include(expired_rsvp)
      end
    end

    describe '.expired' do
      it 'returns RSVPs that have expired' do
        expect(Rsvp.expired).to include(expired_rsvp)
        expect(Rsvp.expired).not_to include(valid_rsvp)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation on create' do
      it 'generates an RSVP token' do
        rsvp = FactoryBot.build(:rsvp, event: event, membership: membership, rsvp_token: nil)
        rsvp.save!
        expect(rsvp.rsvp_token).to be_present
        expect(rsvp.rsvp_token.length).to be > 30
      end

      it 'sets expiration date to 1 hour before event' do
        rsvp = FactoryBot.build(:rsvp, event: event, membership: membership, expires_at: nil)
        rsvp.save!
        expected_expiry = event.event_date - 1.hour
        expect(rsvp.expires_at).to be_within(1.minute).of(expected_expiry)
      end

      it 'does not overwrite existing token' do
        original_token = 'existing_token_12345'
        rsvp = FactoryBot.build(:rsvp, event: event, membership: membership, rsvp_token: original_token)
        rsvp.save!
        expect(rsvp.rsvp_token).to eq(original_token)
      end

      it 'ensures rsvp_token is always present after validation' do
        rsvp = FactoryBot.build(:rsvp, event: event, membership: membership, rsvp_token: nil)
        expect(rsvp.valid?).to be true
        expect(rsvp.rsvp_token).to be_present
      end

      it 'ensures expires_at is always present after validation' do
        rsvp = FactoryBot.build(:rsvp, event: event, membership: membership, expires_at: nil)
        expect(rsvp.valid?).to be true
        expect(rsvp.expires_at).to be_present
      end
    end
  end

  describe 'class methods' do
    let!(:rsvp) { FactoryBot.create(:rsvp, event: event, membership: membership) }

    describe '.find_by_token' do
      it 'finds RSVP by token' do
        found_rsvp = Rsvp.find_by_token(rsvp.rsvp_token)
        expect(found_rsvp).to eq(rsvp)
      end

      it 'returns nil for invalid token' do
        found_rsvp = Rsvp.find_by_token('invalid_token')
        expect(found_rsvp).to be_nil
      end
    end

    describe '.create_for_event_and_membership' do
      let(:new_membership) { FactoryBot.create(:membership, lounge: lounge) }

      it 'creates an RSVP with default values' do
        new_rsvp = nil
        expect do
          new_rsvp = Rsvp.create_for_event_and_membership(event, new_membership)
        end.to change(Rsvp, :count).by(1)

        expect(new_rsvp.event).to eq(event)
        expect(new_rsvp.membership).to eq(new_membership)
        expect(new_rsvp.status).to eq('pending')
        expect(new_rsvp.guest_count).to eq(1)
      end

      it 'creates an RSVP with custom guest count' do
        rsvp = Rsvp.create_for_event_and_membership(event, new_membership, guest_count: 3)
        expect(rsvp.guest_count).to eq(3)
      end
    end
  end

  describe 'instance methods' do
    let(:rsvp) { FactoryBot.create(:rsvp, event: event, membership: membership) }

    describe '#expired?' do
      it 'returns false for non-expired RSVP' do
        rsvp.update!(expires_at: 1.hour.from_now)
        expect(rsvp.expired?).to be false
      end

      it 'returns true for expired RSVP' do
        rsvp.update!(expires_at: 1.hour.ago)
        expect(rsvp.expired?).to be true
      end
    end

    describe '#valid_for_response?' do
      it 'returns true for pending, non-expired RSVP' do
        rsvp.update!(status: :pending, expires_at: 1.hour.from_now)
        expect(rsvp.valid_for_response?).to be true
      end

      it 'returns false for expired RSVP' do
        rsvp.update!(expires_at: 1.hour.ago)
        expect(rsvp.valid_for_response?).to be false
      end

      it 'returns false for non-pending RSVP' do
        rsvp.update!(status: :attending)
        expect(rsvp.valid_for_response?).to be false
      end
    end

    describe '#respond_with' do
      context 'with valid, non-expired RSVP' do
        before { rsvp.update!(expires_at: 1.hour.from_now) }

        it 'updates status' do
          result = rsvp.respond_with('attending')
          expect(result).to be true
          expect(rsvp.reload.status).to eq('attending')
        end

        it 'updates guest count when provided' do
          result = rsvp.respond_with('attending', 3)
          expect(result).to be true
          expect(rsvp.reload.guest_count).to eq(3)
        end

        it 'keeps existing guest count when not provided' do
          rsvp.update!(guest_count: 2)
          rsvp.respond_with('declined')
          expect(rsvp.reload.guest_count).to eq(2)
        end
      end

      context 'with expired RSVP' do
        before { rsvp.update!(expires_at: 1.hour.ago) }

        it 'returns false and does not update' do
          original_status = rsvp.status
          result = rsvp.respond_with('attending')
          expect(result).to be false
          expect(rsvp.reload.status).to eq(original_status)
        end
      end
    end

    describe '#total_attendees' do
      it 'returns guest count for attending RSVP' do
        rsvp.update!(status: :attending, guest_count: 3)
        expect(rsvp.total_attendees).to eq(3)
      end

      it 'returns 0 for non-attending RSVP' do
        rsvp.update!(status: :declined, guest_count: 3)
        expect(rsvp.total_attendees).to eq(0)
      end
    end

    describe '#status_display' do
      it 'returns correct display for pending' do
        rsvp.update!(status: :pending)
        expect(rsvp.status_display).to eq('Awaiting Response')
      end

      it 'returns correct display for attending with guest count' do
        rsvp.update!(status: :attending, guest_count: 1)
        expect(rsvp.status_display).to eq('Attending (1 guest)')

        rsvp.update!(guest_count: 3)
        expect(rsvp.status_display).to eq('Attending (3 guests)')
      end

      it 'returns correct display for declined' do
        rsvp.update!(status: :declined)
        expect(rsvp.status_display).to eq('Not Attending')
      end

      it 'returns correct display for expired' do
        rsvp.update!(status: :expired)
        expect(rsvp.status_display).to eq('Expired')
      end
    end

    describe '#member_name' do
      it 'returns the membership member name' do
        expect(rsvp.member_name).to eq(membership.member_name)
      end
    end

    describe '#event_title' do
      it 'returns the event name' do
        expect(rsvp.event_title).to eq(event.name)
      end
    end
  end
end
