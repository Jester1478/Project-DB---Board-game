<script setup lang="ts">
import { computed, ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const { catalogGames, categories, loading, loadError } = useBoardGameStore()

const search = ref('')
const categoryId = ref('')

const filteredGames = computed(() => {
  const q = search.value.trim().toLowerCase()
  return catalogGames.value.filter(g =>
    g.name.toLowerCase().includes(q)
    && (!categoryId.value || g.categories.some(c => c.id === categoryId.value))
  )
})
</script>

<template>
  <main>
    <div class="section-head">
      <h2>แคตตาล็อกบอร์ดเกม</h2>
      <p>ค้นหาเกม เช็คสต็อกว่าง แล้วกดที่การ์ดเกมเพื่อดูรายละเอียดและจองคิว</p>
    </div>
    <div class="filters">
      <input v-model="search" type="text" placeholder="ค้นหาชื่อเกม...">
      <select v-model="categoryId">
        <option value="">ทุกหมวดหมู่</option>
        <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
      </select>
    </div>
    <p v-if="loadError" class="err">{{ loadError }}</p>
    <p v-else-if="loading" class="empty-row">กำลังโหลดข้อมูลเกม...</p>
    <div v-else class="grid">
      <GameCard v-for="g in filteredGames" :key="g.id" :game="g" />
      <div v-if="filteredGames.length === 0" class="empty-row">ไม่พบเกมที่ค้นหา</div>
    </div>
  </main>
</template>
