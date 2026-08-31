<script setup lang="ts">
import { computed } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const { simNow, setSimNow } = useBoardGameStore()

function toLocalInputValue(d: Date) {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

const clockValue = computed({
  get: () => toLocalInputValue(simNow.value),
  set: (val: string) => {
    if (val) setSimNow(new Date(val))
  }
})
</script>

<template>
  <header class="top">
    <NuxtLink to="/" class="brand">
      <div class="mark">🐍</div>
      <div class="titles">
        <h1>ระบบจองบอร์ดเกม</h1>
        <p>เลือกเกม เช็คคิว แล้วจองได้ทันที</p>
      </div>
    </NuxtLink>
    <div class="header-right">
      <div class="clock-box">
        <span class="lbl">เวลา</span>
        <input v-model="clockValue" type="datetime-local">
      </div>
      <NuxtLink to="/staff" class="staff-link">สำหรับเจ้าหน้าที่ →</NuxtLink>
    </div>
  </header>
</template>
