<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

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

const conversationLabel = conversation =>
  conversation.meta?.sender?.name || `#${conversation.id}`;
</script>

<template>
  <div class="border-b border-n-weak">
    <button
      class="flex items-center w-full gap-3 px-4 py-3 text-left rtl:text-right hover:bg-n-alpha-1"
      @click="emit('toggle', agent.id)"
    >
      <Avatar
        :src="agent.thumbnail"
        :name="agent.name"
        :status="agent.availability_status"
        :size="32"
        hide-offline-status
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

    <div v-if="isExpanded" class="pb-2">
      <div v-if="isLoading" class="flex justify-center py-4 text-n-slate-11">
        <Spinner :size="20" />
      </div>
      <span
        v-else-if="!conversations.length"
        class="block px-4 py-3 text-sm text-n-slate-11"
      >
        {{ $t('AGENT_CONVERSATIONS.NO_CONVERSATIONS') }}
      </span>
      <ul v-else class="m-0 list-none">
        <li v-for="conversation in conversations" :key="conversation.id">
          <button
            class="flex items-center w-full gap-2 py-2 text-sm text-left rtl:text-right ps-14 pe-4 hover:bg-n-alpha-1"
            :class="{
              'bg-n-alpha-2 text-n-slate-12':
                Number(activeConversationId) === conversation.id,
              'text-n-slate-11':
                Number(activeConversationId) !== conversation.id,
            }"
            @click="emit('selectConversation', conversation.id)"
          >
            <span class="truncate">{{ conversationLabel(conversation) }}</span>
            <span class="text-xs capitalize ms-auto text-n-slate-10">
              {{ conversation.status }}
            </span>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
