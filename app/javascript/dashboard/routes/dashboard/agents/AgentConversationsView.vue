<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import AgentConversationList from './components/AgentConversationList.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';

const props = defineProps({
  conversationId: {
    type: [String, Number],
    default: 0,
  },
});

const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const chatList = useMapGetter('getAllConversations');
const currentChat = useMapGetter('getSelectedChat');

const findConversation = () => {
  const id = parseInt(props.conversationId, 10);
  return chatList.value.find(chat => chat.id === id);
};

const setActiveChat = async () => {
  if (!props.conversationId) {
    store.dispatch('clearSelectedState');
    return;
  }

  let conversation = findConversation();
  if (!conversation) {
    await store.dispatch('getConversation', props.conversationId);
    conversation = findConversation();
  }

  if (conversation && conversation.id !== currentChat.value.id) {
    store.dispatch('setActiveChat', { data: conversation });
  }
};

const openConversation = id => {
  router.push(
    accountScopedRoute('agent_conversations_detail', { conversationId: id })
  );
};

const showMessageView = computed(() => Boolean(props.conversationId));

onMounted(() => {
  store.dispatch('agents/get');
  setActiveChat();
});

watch(() => props.conversationId, setActiveChat);
</script>

<template>
  <section class="flex w-full h-full min-w-0">
    <AgentConversationList
      :active-conversation-id="conversationId"
      @select-conversation="openConversation"
    />
    <ConversationBox
      v-if="showMessageView"
      :inbox-id="0"
      :is-on-expanded-layout="false"
    />
  </section>
</template>
