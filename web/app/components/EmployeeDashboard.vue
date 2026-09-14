<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Booking, BookingStatus } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'
import { useEmployeeAuth } from '~/composables/useEmployeeAuth'

const { games, bookings, getUser, userLabel, copyLabel, markInUse, markReturned } = useBoardGameStore()
const { addToast } = useToasts()
const { employee } = useEmployeeAuth()
const route = useRoute()
const router = useRouter()

const search = ref('')

function fmtTime(d: Date) {
  return d.toTimeString().slice(0, 5)
}

// e.g. "จ. 15 ก.ย. 2569" — Thai weekday/month with the Buddhist-era year staff read day to day.
const dateFormat = new Intl.DateTimeFormat('th-TH', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })

function fmtDate(d: Date) {
  return dateFormat.format(d)
}

/** The three stages a booking moves through, in working order. Each is one tab. */
const SECTIONS: { key: string, title: string, subtitle: string, statuses: BookingStatus[] }[] = [
  { key: 'pending', title: 'กำลังดำเนินการ', subtitle: 'จองแล้ว รอส่งมอบเกมให้ลูกค้า', statuses: ['Reserved'] },
  { key: 'out', title: 'รอคืน', subtitle: 'ส่งมอบแล้ว ลูกค้ากำลังเล่นหรือเกินเวลาคืน', statuses: ['In_Use', 'Overdue'] },
  { key: 'done', title: 'คืนสำเร็จ', subtitle: 'คืนเกมเรียบร้อยแล้ว', statuses: ['Returned', 'Cancelled'] }
]

/**
 * Most recently made booking first. The schema has no created-at column, but booking_id
 * is issued in increasing order (BK-001, BK-002, …), so it records the order bookings
 * were made. Compared numerically, so BK-1000 sorts above BK-999.
 */
function newestFirst(a: Booking, b: Booking) {
  return b.id.localeCompare(a.id, undefined, { numeric: true })
}

const sections = computed(() => {
  const q = search.value.trim().toLowerCase()
  const matching = bookings
    .filter(b => {
      const u = getUser(b.userId)
      const hay = `${u?.email ?? ''} ${u?.phone ?? ''} ${userLabel(b.userId)} ${gameFor(b.gameId).name}`.toLowerCase()
      return hay.includes(q)
    })
    .sort(newestFirst)
  return SECTIONS.map(s => ({ ...s, rows: matching.filter(b => s.statuses.includes(b.status)) }))
})

// The open tab lives in the URL (?tab=out), so a refresh or a shared link keeps it.
const activeKey = computed({
  get: () => {
    const tab = String(route.query.tab ?? '')
    return SECTIONS.some(s => s.key === tab) ? tab : SECTIONS[0]!.key
  },
  set: key => { void router.replace({ query: { ...route.query, tab: key } }) }
})

const active = computed(() => sections.value.find(s => s.key === activeKey.value) ?? sections.value[0]!)

const UNKNOWN_GAME = { name: '—', icon: '🎲' }

function gameFor(gameId: string) {
  return games.find(x => x.id === gameId) ?? UNKNOWN_GAME
}

function isArchived(gameId: string) {
  return games.find(x => x.id === gameId)?.archived ?? false
}

const NOT_SAVED = 'บันทึกไม่สำเร็จ — สิทธิ์เจ้าหน้าที่อาจหมดอายุ กรุณาเข้าสู่ระบบใหม่'

async function handleMarkInUse(id: string) {
  if (!employee.value) return addToast(NOT_SAVED, true)
  const b = await markInUse(id, employee.value.id)
  if (b) addToast(`ส่งมอบ ${gameFor(b.gameId).name} (${copyLabel(b.copyId)}) ให้ ${userLabel(b.userId)} แล้ว`, false)
  else addToast(NOT_SAVED, true)
}

async function handleMarkReturned(id: string) {
  if (!employee.value) return addToast(NOT_SAVED, true)
  const b = await markReturned(id, employee.value.id)
  if (b) addToast(`บันทึกคืนสำเร็จ — กล่อง ${copyLabel(b.copyId)} ว่างพร้อมใช้งานทันที`, false)
  else addToast(NOT_SAVED, true)
}
</script>

<template>
  <div>
    <div class="section-head">
      <h2>Employee Dashboard</h2>
      <p>ค้นหารายการจอง ส่งมอบเกม และบันทึกการรับคืน</p>
    </div>
    <div class="employee-search">
      <input v-model="search" type="text" placeholder="ค้นหาด้วยชื่อ, อีเมล, เบอร์โทร, หรือชื่อเกม...">
    </div>

    <div class="sub-tabs" role="tablist">
      <button
        v-for="s in sections"
        :key="s.key"
        type="button"
        role="tab"
        :aria-selected="s.key === activeKey"
        :class="{ active: s.key === activeKey }"
        @click="activeKey = s.key"
      >
        {{ s.title }}
        <span class="count-pill">{{ s.rows.length }}</span>
      </button>
    </div>
    <p class="dim-text tab-subtitle">{{ active.subtitle }}</p>

    <table class="book-table" role="tabpanel">
      <thead>
        <tr><th>เกม / กล่อง</th><th>ผู้จอง</th><th>ช่วงเวลา</th><th>สถานะ</th><th>การจัดการ</th></tr>
      </thead>
      <tbody>
        <tr v-for="b in active.rows" :key="b.id">
          <td>
            {{ gameFor(b.gameId).icon }} {{ gameFor(b.gameId).name }}
            <span v-if="isArchived(b.gameId)" class="dim">(ลบแล้ว)</span><br>
            <span class="mono dim">{{ copyLabel(b.copyId) }}</span>
          </td>
          <td>
            {{ userLabel(b.userId) }}<br>
            <span class="mono dim">{{ getUser(b.userId)?.email }}</span>
          </td>
          <td>
            {{ fmtDate(b.start) }}<br>
            <span class="mono" style="font-size:12px;">{{ fmtTime(b.start) }}–{{ fmtTime(b.end) }}</span>
          </td>
          <td><span class="badge" :class="b.status">{{ b.status }}</span></td>
          <td>
            <button v-if="b.status === 'Reserved'" class="btn btn-inuse btn-sm" @click="handleMarkInUse(b.id)">ส่งมอบ</button>
            <button v-else-if="b.status === 'In_Use' || b.status === 'Overdue'" class="btn btn-ok btn-sm" @click="handleMarkReturned(b.id)">บันทึกคืนสำเร็จ</button>
            <span v-else-if="b.status === 'Returned' && b.actualReturn" class="mono dim">
              คืนเมื่อ {{ fmtDate(b.actualReturn) }} {{ fmtTime(b.actualReturn) }}
            </span>
          </td>
        </tr>
        <tr v-if="active.rows.length === 0">
          <td colspan="5" class="empty-row">{{ search.trim() ? 'ไม่พบรายการที่ค้นหา' : 'ไม่มีรายการ' }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
