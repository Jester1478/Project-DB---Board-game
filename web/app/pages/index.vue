<script setup lang="ts">
import { computed, ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const { games } = useBoardGameStore()

const search = ref('')
const category = ref('')

const categories = computed(() => [...new Set(games.map(g => g.category))])

const filteredGames = computed(() => {
  const q = search.value.trim().toLowerCase()
  return games.filter(g => g.name.toLowerCase().includes(q) && (!category.value || g.category === category.value))
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
      <select v-model="category">
        <option value="">ทุกหมวดหมู่</option>
        <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
      </select>
    </div>
    <div class="grid">
      <GameCard v-for="g in filteredGames" :key="g.id" :game="g" />
      <div v-if="filteredGames.length === 0" class="empty-row">ไม่พบเกมที่ค้นหา</div>
    </div>
  </main>
</template>
