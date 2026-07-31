require 'rails_helper'

RSpec.describe Agents::MarkOfflineService do
  let!(:account) { create(:account) }
  let!(:second_account) { create(:account) }
  let!(:user) { create(:user, account: account, auto_offline: false) }
  let!(:account_user) { user.account_users.find_by!(account: account) }
  let!(:second_account_user) { create(:account_user, account: second_account, user: user, availability: :online, auto_offline: false) }

  describe '#perform' do
    it 'sets the user offline across accounts and clears presence' do
      expect(OnlineStatusTracker).to receive(:mark_user_offline).with(account.id, user.id)
      expect(OnlineStatusTracker).to receive(:mark_user_offline).with(second_account.id, user.id)

      described_class.new(user: user).perform

      expect(account_user.reload.availability).to eq('offline')
      expect(second_account_user.reload.availability).to eq('offline')
    end
  end
end
