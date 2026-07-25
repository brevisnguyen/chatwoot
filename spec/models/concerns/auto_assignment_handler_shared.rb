# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'auto_assignment_handler' do
  describe '#auto assignment' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account, auto_offline: false) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) do
      create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        assignee: nil
      )
    end

    before do
      create(:inbox_member, inbox: inbox, user: agent)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent.id)
    end

    it 'runs round robin on after_save callbacks' do
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'will not auto assign agent if enable_auto_assignment is false' do
      inbox.update(enable_auto_assignment: false)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'will not auto assign agent if its a bot conversation' do
      conversation = create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        status: 'pending',
        assignee: nil
      )

      expect(conversation.reload.assignee).to be_nil
    end

    it 'gets triggered on update only when status changes to open' do
      conversation.status = 'resolved'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent)
      inbox.inbox_members.where(user_id: agent.id).first.destroy!

      # round robin changes assignee in this case since agent doesn't have access to inbox
      agent2 = create(:user, email: 'agent2@example.com', account: account, auto_offline: false)
      create(:inbox_member, inbox: inbox, user: agent2)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent2.id)
      conversation.status = 'open'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent2)
    end

    context 'when reopening with an offline assignee' do
      let(:offline_agent) { create(:user, email: 'offline@example.com', account: account, auto_offline: false) }
      let(:online_agent) { create(:user, email: 'online@example.com', account: account, auto_offline: false) }

      before do
        inbox.inbox_members.destroy_all
        create(:inbox_member, inbox: inbox, user: offline_agent)
        create(:inbox_member, inbox: inbox, user: online_agent)
      end

      context 'with legacy assignment' do
        before do
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'offline',
            online_agent.id.to_s => 'online'
          )
          allow_any_instance_of(AutoAssignment::InboxRoundRobinService).to receive(:available_agent) do |_instance, allowed_agent_ids:|
            next nil if allowed_agent_ids.blank?

            online_agent if allowed_agent_ids.map(&:to_s).include?(online_agent.id.to_s)
          end
        end

        it 'reassigns to an online agent when status changes from resolved to open' do
          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(online_agent)
        end

        it 'reassigns to an online agent when status changes from pending to open' do
          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :pending
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(online_agent)
        end

        it 'keeps the offline assignee when no agents are online' do
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'offline',
            online_agent.id.to_s => 'offline'
          )

          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(offline_agent)
        end

        it 'keeps the assignee when they are still online' do
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'online',
            online_agent.id.to_s => 'online'
          )

          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(offline_agent)
        end
      end

      context 'with assignment v2' do
        let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }
        let(:rate_limiter) { instance_double(AutoAssignment::RateLimiter) }
        let(:round_robin_selector) { instance_double(AutoAssignment::RoundRobinSelector) }

        before do
          account.enable_features('assignment_v2')
          account.save!
          create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'offline',
            online_agent.id.to_s => 'online'
          )
          allow(AutoAssignment::RoundRobinSelector).to receive(:new).and_return(round_robin_selector)
          allow(round_robin_selector).to receive(:select_agent).and_return(online_agent)
          allow(AutoAssignment::RateLimiter).to receive(:new).and_return(rate_limiter)
          allow(rate_limiter).to receive(:within_limit?).and_return(true)
          allow(rate_limiter).to receive(:track_assignment)
          allow(AutoAssignment::AssignmentJob).to receive(:enqueue_for_inbox) do |inbox_id|
            AutoAssignment::AssignmentJob.perform_now(inbox_id: inbox_id)
          end
        end

        it 'reassigns to an online agent when status changes from resolved to open' do
          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(online_agent)
        end

        it 'reassigns to an online agent when status changes from pending to open' do
          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :pending
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(online_agent)
        end

        it 'keeps the offline assignee when no agents are online' do
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'offline',
            online_agent.id.to_s => 'offline'
          )

          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(offline_agent)
        end

        it 'keeps the assignee when they are still online' do
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
            offline_agent.id.to_s => 'online',
            online_agent.id.to_s => 'online'
          )

          conversation = create(
            :conversation,
            account: account,
            contact: create(:contact, account: account),
            inbox: inbox,
            assignee: offline_agent,
            status: :resolved
          )

          conversation.update!(status: :open)

          expect(conversation.reload.assignee).to eq(offline_agent)
        end
      end
    end
  end
end
