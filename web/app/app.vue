<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const { syncToRealTime } = useBoardGameStore()

// Keep the clock on the device's real local time (and re-evaluate Overdue).
// 10s keeps the displayed minute honest without noticeable cost.
let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  syncToRealTime()
  timer = setInterval(syncToRealTime, 10_000)
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
