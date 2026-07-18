<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../../provider.js';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { formatGreetingContent } from 'shared/helpers/greetingContentHelper';
import { MESSAGE_VARIANTS } from '../../constants';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { variant, contentAttributes } = useMessageContext();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return formatGreetingContent(
    props.content,
    contentAttributes.value,
    content => new MessageFormatter(content).formattedMessage
  );
});
</script>

<template>
  <span v-dompurify-html="formattedContent" class="prose prose-bubble" />
</template>
