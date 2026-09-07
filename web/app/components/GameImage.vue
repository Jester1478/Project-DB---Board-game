<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  src?: string
  icon: string
  alt: string
}>()

// A missing or broken image file falls back to the emoji instead of a broken-image box.
const failed = ref(false)
watch(() => props.src, () => { failed.value = false })
</script>

<template>
  <img v-if="src && !failed" :src="src" :alt="alt" @error="failed = true">
  <span v-else>{{ icon }}</span>
</template>
