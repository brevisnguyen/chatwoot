<script setup>
import { computed } from 'vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import GreetingsTinyMCE from 'shared/components/GreetingsTinyMCE.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  richtext: { type: Boolean, default: false },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);

const greetingsMessage = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});
</script>

<template>
  <section>
    <GreetingsTinyMCE
      v-if="richtext"
      v-model="greetingsMessage"
      :placeholder="placeholder"
    />
    <ResizableTextArea
      v-else
      v-model="greetingsMessage"
      :rows="4"
      :min-height="4"
      type="text"
      class="bg-transparent p-0 !outline-0 !outline-none !mb-0 mt-1 text-sm"
      :label="label"
      :placeholder="placeholder"
    />
  </section>
</template>
