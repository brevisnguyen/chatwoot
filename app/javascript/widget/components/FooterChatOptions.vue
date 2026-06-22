<script setup>
import { useStore } from 'vuex';
import ChatOption from 'shared/components/ChatOption.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  messageId: {
    type: Number,
    default: null,
  },
});

const store = useStore();

const onOptionSelect = selectedOption => {
  store.dispatch('message/update', {
    submittedValues: [selectedOption],
    messageId: props.messageId,
  });
};
</script>

<template>
  <ul class="flex gap-2 overflow-x-auto px-1 pb-2 list-none m-0">
    <ChatOption
      v-for="(option, index) in options"
      :key="option.id ?? option.value ?? index"
      class="!m-0 shrink-0 list-none"
      :action="option"
      @option-select="onOptionSelect"
    />
  </ul>
</template>
