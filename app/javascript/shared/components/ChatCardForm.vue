<script setup>
import { computed } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ChatForm from 'shared/components/ChatForm.vue';

const props = defineProps({
  mediaUrl: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
  submittedValues: {
    type: Array,
    default: () => [],
  },
});

defineEmits(['submit']);

const { formatMessage } = useMessageFormatter();

const normalizedDescription = computed(() =>
  (props.description || '').replace(/<br\s*\/?>/gi, '\n')
);
</script>

<template>
  <div
    class="card-form chat-bubble agent bg-n-background dark:bg-n-solid-3 w-full max-w-80 rounded-lg overflow-hidden"
  >
    <img
      v-if="mediaUrl"
      class="w-full object-contain max-h-[150px]"
      :src="mediaUrl"
    />
    <div class="pt-4">
      <h4
        v-if="title"
        class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-n-slate-12"
      >
        {{ title }}
      </h4>
      <div
        v-if="description"
        v-dompurify-html="formatMessage(normalizedDescription, false)"
        class="!mb-2 text-sm text-n-slate-11"
      />
      <ChatForm
        embedded
        :items="items"
        :button-label="buttonLabel"
        :submitted-values="submittedValues"
        @submit="$emit('submit', $event)"
      />
    </div>
  </div>
</template>
