<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const { tick } = useBoardGameStore()

let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  timer = setInterval(() => tick(1), 8000)
})
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="app-shell">
    <SiteHeader />
    <NuxtPage />
    <footer>Prototype UI — จำลองข้อมูลในเบราว์เซอร์เท่านั้น ไม่ได้เชื่อมต่อฐานข้อมูลจริง</footer>
    <ToastStack />
  </div>
</template>
