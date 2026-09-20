<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { NO_SHOW_GRACE_MINUTES, useBoardGameStore } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

// Opening hours, in 30-minute slots.
const DAY_START = 8
const DAY_END = 22
const SLOT_MINUTES = 30

const props = defineProps<{ gameId: string }>()
const emit = defineEmits<{ (e: 'close'): void }>()

const { getGame, usableCopies, copyStatus, todayAt, simNow, addBooking } = useBoardGameStore()
const { addToast } = useToasts()

function fmtTime(d: Date) {
  return d.toTimeString().slice(0, 5)
}

/** "14:30" -> { h: 14, m: 30 }; falls back to 0 so a cleared field can't produce NaN. */
function parseTime(value: string) {
  const [h, m] = value.split(':').map(Number)
  return { h: h ?? 0, m: m ?? 0 }
}

function toMinutes(value: string) {
  const { h, m } = parseTime(value)
  return h * 60 + m
}

function fromMinutes(total: number) {
  const h = Math.floor(total / 60)
  const m = total % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

/** Every 30-minute mark between opening and closing time. */
const allSlots = computed(() => {
  const slots: string[] = []
  for (let m = DAY_START * 60; m <= DAY_END * 60; m += SLOT_MINUTES) slots.push(fromMinutes(m))
  return slots
})

/** The next 30-minute mark from now, never earlier than opening time. */
const earliestStart = computed(() => {
  const mins = simNow.value.getHours() * 60 + simNow.value.getMinutes()
  return Math.max(DAY_START * 60, Math.ceil(mins / SLOT_MINUTES) * SLOT_MINUTES)
})

/**
 * Only slots that haven't happened yet — booking in the past is not allowed.
 * The latest start offered is 30 minutes before closing, so the shortest
 * booking BR-02 permits still fits inside opening hours.
 */
const startSlots = computed(() => allSlots.value.filter(s => {
  const mins = toMinutes(s)
  return mins >= earliestStart.value && mins <= DAY_END * 60 - SLOT_MINUTES
}))

/** Past the last bookable start of the day, there is nothing left to book. */
const closedForToday = computed(() => startSlots.value.length === 0)

const game = getGame(props.gameId)!
// Only boxes in lendable condition can be booked.
const copies = usableCopies(game)
const firstFree = copies.find(c => copyStatus(c) === 'free')

const selectedCopyId = ref(firstFree?.id ?? copies[0]?.id ?? '')
const firstName = ref('')
const lastName = ref('')
const email = ref('')
const phone = ref('')
const startTime = ref('')
const errorMessage = ref('')

// The clock advances every 10s; if the chosen start slips into the past, move it on.
watch(startSlots, slots => {
  if (!slots.includes(startTime.value)) startTime.value = slots[0] ?? ''
}, { immediate: true })

/** BR-02: 30 minutes minimum, 4 hours maximum — so only those end slots are offered. */
const endSlots = computed(() => {
  const from = toMinutes(startTime.value)
  return allSlots.value.filter(s => {
    const mins = toMinutes(s) - from
    return mins >= SLOT_MINUTES && mins <= 240
  })
})

const endTime = ref('')
watch(endSlots, slots => {
  if (!slots.includes(endTime.value)) endTime.value = slots[0] ?? ''
}, { immediate: true })

const saving = ref(false)

async function submit() {
  if (saving.value || closedForToday.value) return
  const from = parseTime(startTime.value)
  const to = parseTime(endTime.value)

  saving.value = true
  const { error } = await addBooking({
    firstName: firstName.value,
    lastName: lastName.value,
    email: email.value,
    phone: phone.value,
    gameId: props.gameId,
    copyId: selectedCopyId.value,
    start: todayAt(from.h, from.m),
    end: todayAt(to.h, to.m)
  })

  saving.value = false

  if (error) {
    errorMessage.value = error
    return
  }

  addToast(`จองสำเร็จ! ส่งอีเมลยืนยันไปที่ ${email.value.trim()} แล้ว`, false)
  emit('close')
}
</script>

<template>
  <div class="overlay show">
    <div class="modal">
      <h3>จองคิวบอร์ดเกม</h3>
      <div class="sub">{{ game.icon }} {{ game.name }}</div>
      <p class="play-note">
        เวลาเล่นต่อรอบประมาณ <strong>{{ game.playtime }} นาที</strong> · {{ game.minP }}-{{ game.maxP }} ผู้เล่น
      </p>
      <div v-if="errorMessage" class="err show">{{ errorMessage }}</div>
      <div v-if="closedForToday" class="err show">
        วันนี้เลยเวลารับจองแล้ว (รับจองเริ่มได้ถึง 21:30) กรุณาจองใหม่ในวันถัดไป
      </div>
      <div class="field">
        <label>กล่อง</label>
        <select v-model="selectedCopyId">
          <option v-for="copy in copies" :key="copy.id" :value="copy.id">
            {{ copy.label }} — {{ copyStatus(copy) === 'free' ? 'ว่าง' : 'ไม่ว่าง' }}
          </option>
        </select>
      </div>
      <div class="row2">
        <div class="field">
          <label>ชื่อ</label>
          <input v-model="firstName" type="text" placeholder="ชื่อจริง">
        </div>
        <div class="field">
          <label>นามสกุล</label>
          <input v-model="lastName" type="text" placeholder="นามสกุล">
        </div>
      </div>
      <div class="field">
        <label>อีเมล</label>
        <input v-model="email" type="email" placeholder="you@example.com">
      </div>
      <div class="field">
        <label>เบอร์โทร <span class="optional">(ไม่บังคับ)</span></label>
        <input v-model="phone" type="tel" placeholder="08XXXXXXXX">
      </div>
      <div class="row2">
        <div class="field">
          <label>เวลาเริ่ม</label>
          <select v-model="startTime" :disabled="closedForToday">
            <option v-for="slot in startSlots" :key="slot" :value="slot">{{ slot }}</option>
          </select>
        </div>
        <div class="field">
          <label>เวลาสิ้นสุด</label>
          <select v-model="endTime">
            <option v-for="slot in endSlots" :key="slot" :value="slot">{{ slot }}</option>
          </select>
        </div>
      </div>
      <p class="hint">
        * จองล่วงหน้าเท่านั้น จองย้อนหลังไม่ได้ · เลือกได้ทีละ 30 นาที
        เปิดให้จอง 08:00–22:00 · ครั้งละ 30 นาที – 4 ชั่วโมง (BR-01–BR-04)
      </p>
      <p class="hint hint-warn">
        กรุณามารับเกมภายใน {{ NO_SHOW_GRACE_MINUTES }} นาทีหลังเวลาเริ่ม
        หากเลยกำหนด ระบบจะยกเลิกการจองอัตโนมัติและปล่อยกล่องให้คนอื่นจองต่อ
      </p>
      <div class="modal-actions">
        <button class="btn btn-ghost" :disabled="saving" @click="emit('close')">ยกเลิก</button>
        <button class="btn btn-primary" :disabled="saving || closedForToday" @click="submit">
          {{ saving ? 'กำลังบันทึก...' : 'ยืนยันการจอง' }}
        </button>
      </div>
    </div>
  </div>
</template>
