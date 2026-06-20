require 'rails_helper'

RSpec.describe Conversations::ResolutionJob do
  subject(:job) { described_class.perform_later(account: account) }

  let!(:account) { create(:account) }
  let(:label) { create(:label, title: 'auto-resolved', account: account) }
  let!(:conversation) { create(:conversation, account: account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account: account)
      .on_queue('low')
  end

  it 'does nothing when there is no auto resolve duration' do
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('open')
  end

  context 'when auto_resolve_ignore_waiting is true' do
    it 'resolves non-waiting conversations if time of inactivity is more than auto resolve duration' do
      account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: true) # 10 days in minutes
      conversation.update(last_activity_at: 13.days.ago, waiting_since: nil)
      described_class.perform_now(account: account)
      expect(conversation.reload.status).to eq('resolved')
    end

    it 'does not resolve waiting conversations even if time of inactivity is more than auto resolve duration' do
      account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: true) # 10 days in minutes
      conversation.update(last_activity_at: 13.days.ago, waiting_since: 13.days.ago)
      described_class.perform_now(account: account)
      expect(conversation.reload.status).to eq('open')
    end
  end

  context 'when auto_resolve_ignore_waiting is false' do
    it 'resolves all conversations if time of inactivity is more than auto resolve duration' do
      account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: false) # 10 days in minutes
      # Create one waiting conversation and one non-waiting conversation
      waiting_conversation = create(:conversation, account: account, last_activity_at: 13.days.ago, waiting_since: 13.days.ago)
      non_waiting_conversation = create(:conversation, account: account, last_activity_at: 13.days.ago, waiting_since: nil)

      described_class.perform_now(account: account)

      expect(waiting_conversation.reload.status).to eq('resolved')
      expect(non_waiting_conversation.reload.status).to eq('resolved')
    end
  end

  context 'when conversations are pending or snoozed' do
    before do
      account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: false) # 10 days in minutes
    end

    it 'resolves pending conversations' do
      pending_conversation = create(:conversation, account: account, status: :pending, last_activity_at: 13.days.ago)
      described_class.perform_now(account: account)
      expect(pending_conversation.reload.status).to eq('resolved')
    end

    it 'resolves snoozed conversations and clears snoozed_until' do
      snoozed_conversation = create(:conversation, account: account, status: :snoozed, snoozed_until: 2.days.from_now,
                                                   last_activity_at: 13.days.ago)
      described_class.perform_now(account: account)
      expect(snoozed_conversation.reload.status).to eq('resolved')
      expect(snoozed_conversation.reload.snoozed_until).to be_nil
    end

    it 'does not pick up already resolved conversations' do
      resolved_conversation = create(:conversation, account: account, status: :resolved, last_activity_at: 13.days.ago)
      expect(account.conversations.resolvable_all(account.auto_resolve_after)).not_to include(resolved_conversation)
      described_class.perform_now(account: account)
      expect(resolved_conversation.reload.status).to eq('resolved')
    end
  end

  context 'when auto_resolve_ignore_waiting is true with pending or snoozed conversations' do
    before do
      account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: true) # 10 days in minutes
    end

    it 'skips snoozed conversations that are waiting for an agent reply' do
      snoozed_waiting = create(:conversation, account: account, status: :snoozed, snoozed_until: 2.days.from_now,
                                              last_activity_at: 13.days.ago, waiting_since: 13.days.ago)
      described_class.perform_now(account: account)
      expect(snoozed_waiting.reload.status).to eq('snoozed')
    end
  end

  # When a contact is deleted, there's a brief window (~50-150ms) where contact_id becomes nil
  # but conversations still exist. If ResolutionJob runs during this window, muted? can crash
  # trying to call blocked? on nil. Fixes # (issue).
  it 'skips orphan conversations without a contact' do
    account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: false) # 10 days in minutes
    orphan_conversation = create(:conversation, account: account, last_activity_at: 13.days.ago, waiting_since: nil)
    orphan_conversation.update_columns(contact_id: nil, contact_inbox_id: nil) # rubocop:disable Rails/SkipsModelValidations
    resolvable_conversation = create(:conversation, account: account, last_activity_at: 13.days.ago, waiting_since: nil)

    described_class.perform_now(account: account)

    expect(orphan_conversation.reload.status).to eq('open')
    expect(resolvable_conversation.reload.status).to eq('resolved')
  end

  it 'adds a label after resolution' do
    account.update(auto_resolve_label: 'auto-resolved', auto_resolve_after: 14_400)
    conversation = create(:conversation, account: account, last_activity_at: 13.days.ago, waiting_since: 13.days.ago)

    described_class.perform_now(account: account)

    expect(conversation.reload.status).to eq('resolved')
    expect(conversation.reload.label_list).to include('auto-resolved')
  end

  it 'resolves only a limited number of conversations in a single execution' do
    stub_const('Limits::BULK_ACTIONS_LIMIT', 2)
    account.update(auto_resolve_after: 14_400, auto_resolve_ignore_waiting: false) # 10 days in minutes
    create_list(:conversation, 3, account: account, last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(account.conversations.resolved.count).to eq(Limits::BULK_ACTIONS_LIMIT)
  end
end
