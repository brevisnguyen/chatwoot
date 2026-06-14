<script setup>
import { computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
  count: {
    type: Number,
    default: 0,
  },
  isExpanded: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  conversations: {
    type: Array,
    default: () => [],
  },
  activeConversationId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['toggle', 'selectConversation']);

const store = useStore();
const inboxesList = useMapGetter('inboxes/getInboxes');

const showInboxName = computed(() => inboxesList.value.length > 1);

const getContact = conversation => conversation.meta?.sender || {};

const getAssignee = conversation => conversation.meta?.assignee || {};

const getInbox = conversation => {
  const inboxId = conversation.inbox_id;
  return inboxId ? store.getters['inboxes/getInbox'](inboxId) : {};
};

const isActiveConversation = conversation =>
  Number(props.activeConversationId) === conversation.id;
</script>

<template>
  <div class="border-b border-n-weak">
    <button
      class="flex items-center w-full gap-3 px-4 py-3 text-left rtl:text-right hover:bg-n-alpha-1"
      :class="{ 'bg-n-alpha-1': isExpanded }"
      @click="emit('toggle', agent.id)"
    >
      <Avatar
        :src="agent.thumbnail"
        :name="agent.name"
        :status="agent.availability_status"
        :size="32"
        rounded-full
      />
      <div class="flex flex-col min-w-0">
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ agent.name }}
        </span>
        <span class="text-xs truncate text-n-slate-11">
          {{ agent.email }}
        </span>
      </div>
      <div class="flex items-center gap-2 ms-auto">
        <span
          v-if="count"
          class="inline-flex items-center justify-center min-w-5 h-5 px-1.5 text-xs font-medium rounded-full bg-n-alpha-2 text-n-slate-12"
        >
          {{ count }}
        </span>
        <Icon
          icon="i-lucide-chevron-down"
          class="size-4 text-n-slate-11 transition-transform"
          :class="{ 'rotate-180': isExpanded }"
        />
      </div>
    </button>

    <div
      v-if="isExpanded"
      class="bg-n-background ltr:ml-7 rtl:mr-7 ltr:pl-2 rtl:pr-2 ltr:border-l rtl:border-r border-n-weak"
    >
      <div v-if="isLoading" class="flex justify-center py-4 text-n-slate-11">
        <Spinner :size="20" />
      </div>
      <span
        v-else-if="!conversations.length"
        class="block px-4 py-3 text-sm text-n-slate-11"
      >
        {{ $t('AGENT_CONVERSATIONS.NO_CONVERSATIONS') }}
      </span>
      <ConversationCard
        v-for="conversation in conversations"
        v-else
        :key="conversation.id"
        :chat="conversation"
        :current-contact="getContact(conversation)"
        :assignee="getAssignee(conversation)"
        :inbox="getInbox(conversation)"
        :is-active-chat="isActiveConversation(conversation)"
        :show-inbox-name="showInboxName"
        @click="emit('selectConversation', conversation.id)"
      />
    </div>
  </div>
</template>
