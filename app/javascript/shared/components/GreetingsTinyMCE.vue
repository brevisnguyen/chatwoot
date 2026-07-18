<script setup>
import { computed } from 'vue';
import Editor from '@tinymce/tinymce-vue';

import 'tinymce/tinymce';
import 'tinymce/themes/silver';
import 'tinymce/icons/default';
import 'tinymce/models/dom';
import 'tinymce/plugins/link';
import 'tinymce/plugins/charmap';

import 'tinymce/skins/ui/oxide/skin.min.css';

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);

const content = computed({
  get: () => props.modelValue || '',
  set: value => emit('update:modelValue', value || ''),
});

const editorInit = computed(() => ({
  menubar: false,
  statusbar: false,
  branding: false,
  promotion: false,
  height: 160,
  resize: false,
  plugins: 'link charmap',
  toolbar:
    'bold italic link | alignleft aligncenter alignright | forecolor backcolor | charmap | undo redo',
  toolbar_mode: 'sliding',
  placeholder: props.placeholder,
  convert_urls: false,
  link_default_target: '_blank',
  link_assume_external_targets: true,
  content_style:
    'body { font-family: inherit; font-size: 14px; line-height: 1.5; margin: 8px; }',
  skin: false,
  content_css: false,
}));
</script>

<template>
  <div
    class="greetings-tinymce mt-1 overflow-hidden rounded-lg border border-n-weak bg-n-background"
  >
    <Editor v-model="content" license-key="gpl" :init="editorInit" />
  </div>
</template>

<style>
.greetings-tinymce .tox-tinymce {
  border: 0 !important;
  border-radius: 0 !important;
}

.greetings-tinymce .tox .tox-edit-area__iframe {
  background-color: transparent;
}
</style>
