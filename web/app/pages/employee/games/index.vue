<script setup lang="ts">
import { computed, ref } from 'vue'
import { isUsableCopy, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Game } from '~/composables/useBoardGameStore'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const { games, loading, loadError } = useBoardGameStore()

const search = ref('')

const rows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return games.filter(g => `${g.name} ${g.id} ${g.category}`.toLowerCase().includes(q))
})

function stock(game: Game) {
  const usable = game.copies.filter(isUsableCopy).length
  return { usable, retired: game.copies.length - usable }
}
</script>

<template>
  <main>
    <div class="section-head section-head-row">
      <div>
        <h2>จัดการเกม</h2>
        <p>แก้ไขข้อมูลเกม เพิ่มเกมใหม่ และปรับจำนวนกล่องในสต๊อก</p>
      </div>
      <NuxtLink to="/employee/games/new" class="btn btn-primary btn-lg">+ เพิ่มเกมใหม่</NuxtLink>
    </div>

    <div class="employee-search">
      <input v-model="search" type="text" placeholder="ค้นหาด้วยชื่อเกม รหัสเกม หรือหมวดหมู่...">
    </div>

    <p v-if="loadError" class="err">โหลดข้อมูลไม่สำเร็จ: {{ loadError }}</p>

    <table class="book-table catalog-table">
      <thead>
        <tr><th>เกม</th><th>หมวดหมู่</th><th>ผู้เล่น · เวลา</th><th>สต๊อก</th><th /></tr>
      </thead>
      <tbody>
        <tr v-for="g in rows" :key="g.id">
          <td>
            {{ g.icon }} {{ g.name }}<br>
            <span class="mono dim">{{ g.id }}</span>
          </td>
          <td>{{ g.category }}</td>
          <td>{{ g.minP }}-{{ g.maxP }} คน · {{ g.playtime }} นาที</td>
          <td>
            พร้อมให้บริการ <strong>{{ stock(g).usable }}</strong> กล่อง
            <span v-if="stock(g).retired" class="dim"><br>งดให้บริการ {{ stock(g).retired }} กล่อง</span>
          </td>
          <td class="cell-right">
            <NuxtLink :to="`/employee/games/${g.id}`" class="btn btn-ghost btn-sm">แก้ไข</NuxtLink>
          </td>
        </tr>
        <tr v-if="!rows.length">
          <td colspan="5" class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกม' }}</td>
        </tr>
      </tbody>
    </table>
  </main>
</template>
