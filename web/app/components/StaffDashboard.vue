<script setup lang="ts">
import { computed, ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

const { games, bookings, markInUse, markReturned } = useBoardGameStore()
const { addToast } = useToasts()

const search = ref('')

function fmtTime(d: Date) {
  return d.toTimeString().slice(0, 5)
}

const rows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return bookings
    .slice()
    .sort((a, b) => +a.start - +b.start)
    .filter(b => {
      const g = games.find(x => x.id === b.gameId)!
      const hay = `${b.studentId} ${b.studentName} ${g.name}`.toLowerCase()
      return hay.includes(q)
    })
})

function gameFor(gameId: string) {
  return games.find(x => x.id === gameId)!
}

function handleMarkInUse(id: string) {
  const b = markInUse(id)
  if (b) addToast(`ส่งมอบ ${gameFor(b.gameId).name} (${b.copyId}) ให้ ${b.studentName} แล้ว`, false)
}

function handleMarkReturned(id: string) {
  const b = markReturned(id)
  if (b) addToast(`บันทึกคืนสำเร็จ — กล่อง ${b.copyId} ว่างพร้อมใช้งานทันที`, false)
}
</script>

<template>
  <div>
    <div class="section-head">
      <h2>Employee Dashboard</h2>
      <p>ค้นหารายการจอง ส่งมอบเกม และบันทึกการรับคืน</p>
    </div>
    <div class="staff-search">
      <input v-model="search" type="text" placeholder="ค้นหาด้วยรหัสนิสิต, ชื่อ, หรือชื่อเกม...">
    </div>
    <table class="book-table">
      <thead>
        <tr><th>เกม / กล่อง</th><th>ผู้จอง</th><th>ช่วงเวลา</th><th>สถานะ</th><th>การจัดการ</th></tr>
      </thead>
      <tbody>
        <tr v-for="b in rows" :key="b.id">
          <td>
            {{ gameFor(b.gameId).icon }} {{ gameFor(b.gameId).name }}<br>
            <span class="mono dim">{{ b.copyId }}</span>
          </td>
          <td>
            {{ b.studentName }}<br>
            <span class="mono dim">{{ b.studentId }}</span>
          </td>
          <td class="mono" style="font-size:12px;">{{ fmtTime(b.start) }}–{{ fmtTime(b.end) }}</td>
          <td><span class="badge" :class="b.status">{{ b.status }}</span></td>
          <td>
            <button v-if="b.status === 'Reserved'" class="btn btn-inuse btn-sm" @click="handleMarkInUse(b.id)">ส่งมอบ</button>
            <button v-else-if="b.status === 'In_Use' || b.status === 'Overdue'" class="btn btn-ok btn-sm" @click="handleMarkReturned(b.id)">บันทึกคืนสำเร็จ</button>
            <span v-else-if="b.status === 'Returned'" class="mono dim">
              คืนเมื่อ {{ b.actualReturn ? fmtTime(b.actualReturn) : '' }}
            </span>
          </td>
        </tr>
        <tr v-if="rows.length === 0">
          <td colspan="5" class="empty-row">ไม่พบรายการจอง</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
