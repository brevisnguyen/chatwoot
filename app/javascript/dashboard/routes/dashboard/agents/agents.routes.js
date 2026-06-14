import { frontendURL } from '../../../helper/URLHelper';
import AgentConversationsView from './AgentConversationsView.vue';

const PERMISSIONS = ['administrator'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/agents'),
      name: 'agent_conversations',
      meta: {
        permissions: PERMISSIONS,
      },
      component: AgentConversationsView,
    },
    {
      path: frontendURL(
        'accounts/:accountId/agents/conversations/:conversationId'
      ),
      name: 'agent_conversations_detail',
      meta: {
        permissions: PERMISSIONS,
      },
      component: AgentConversationsView,
      props: route => ({ conversationId: route.params.conversationId }),
    },
  ],
};
