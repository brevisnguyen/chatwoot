require 'rails_helper'

RSpec.describe UserSessionRevocationService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  def seed_token(client_id, expiry_offset_days: 30, with_session: true)
    user.tokens = user.tokens.merge(
      client_id => { 'token' => 'x', 'expiry' => (Time.current + expiry_offset_days.days).to_i }
    )
    user.save!
    user.user_sessions.create!(client_id: client_id, last_activity_at: Time.current) if with_session
  end

  describe '#active_token_client_ids' do
    it 'returns only non-expired token client ids' do
      seed_token('live', expiry_offset_days: 30)
      seed_token('expired', expiry_offset_days: -1, with_session: false)

      expect(service.active_token_client_ids).to contain_exactly('live')
    end
  end

  describe '#revoke_token!' do
    it 'removes the token entry for the client' do
      seed_token('to-revoke')

      service.revoke_token!('to-revoke')

      expect(user.reload.tokens.keys).not_to include('to-revoke')
    end
  end

  describe '#revoke_other_sessions!' do
    it 'revokes tracked sessions except the current client' do
      seed_token('keep')
      seed_token('drop-a')
      seed_token('drop-b')

      revoked = service.revoke_other_sessions!(except_client_id: 'keep')

      expect(revoked).to contain_exactly('drop-a', 'drop-b')
      expect(user.reload.tokens.keys).to eq(['keep'])
      expect(user.user_sessions.pluck(:client_id)).to eq(['keep'])
    end

    it 'revokes orphan tokens without UserSession rows' do
      seed_token('keep')
      seed_token('orphan', with_session: false)

      revoked = service.revoke_other_sessions!(except_client_id: 'keep')

      expect(revoked).to include('orphan')
      expect(user.reload.tokens.keys).to eq(['keep'])
    end

    it 'returns an empty array when except_client_id is blank' do
      seed_token('keep')

      expect(service.revoke_other_sessions!(except_client_id: nil)).to eq([])
      expect(user.reload.tokens.keys).to include('keep')
    end
  end

  describe '#revoke_other_sessions_and_notify!' do
    it 'broadcasts user:logout with revoked client_ids' do
      seed_token('keep')
      seed_token('drop')

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [user.pubsub_token],
        'user:logout',
        { reason: 'session_replaced', client_ids: ['drop'] }
      )

      service.revoke_other_sessions_and_notify!(except_client_id: 'keep')
    end

    it 'does not broadcast when nothing was revoked' do
      seed_token('keep')

      expect(ActionCableBroadcastJob).not_to receive(:perform_later)

      service.revoke_other_sessions_and_notify!(except_client_id: 'keep')
    end
  end
end
