<script setup lang="ts">
import { ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

const props = defineProps<{ gameId: string }>()
const emit = defineEmits<{ (e: 'close'): void }>()

const { getGame, copyStatus, todayAt, simNow, addBooking } = useBoardGameStore()
const { addToast } = useToasts()

function fmtTime(d: Date) {
  return d.toTimeString().slice(0, 5)
}

/** "14:30" -> { h: 14, m: 30 }; falls back to 0 so a cleared field can't produce NaN. */
function parseTime(value: string) {
  const [h, m] = value.split(':').map(Number)
  return { h: h ?? 0, m: m ?? 0 }
}

const game = getGame(props.gameId)!
const firstFree = game.copies.find(c => copyStatus(c) === 'free')

const selectedCopyId = ref(firstFree?.id ?? game.copies[0]?.id ?? '')
const firstName = ref('')
const lastName = ref('')
const email = ref('')
const phone = ref('')
const startTime = ref(fmtTime(simNow.value))
const endTime = ref(fmtTime(new Date(simNow.value.getTime() + 60 * 60000)))
const errorMessage = ref('')

function submit() {
  const from = parseTime(startTime.value)
  const to = parseTime(endTime.value)

  const { error } = addBooking({
    firstName: firstName.value,
    lastName: lastName.value,
    email: email.value,
    phone: phone.value,
    gameId: props.gameId,
    copyId: selectedCopyId.value,
    start: todayAt(from.h, from.m),
    end: todayAt(to.h, to.m)
  })

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
      <div v-if="errorMessage" class="err show">{{ errorMessage }}</div>
      <div class="field">
        <label>กล่อง</label>
        <select v-model="selectedCopyId">
          <option v-for="copy in game.copies" :key="copy.id" :value="copy.id">
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
          <input v-model="startTime" type="time">
        </div>
        <div class="field">
          <label>เวลาสิ้นสุด</label>
          <input v-model="endTime" type="time">
        </div>
      </div>
      <p class="hint">* จองได้ครั้งละ 30 นาที – 4 ชั่วโมง และห้ามจองซ้อนกับคิวอื่น (BR-01–BR-04)</p>
      <div class="modal-actions">
        <button class="btn btn-ghost" @click="emit('close')">ยกเลิก</button>
        <button class="btn btn-primary" @click="submit">ยืนยันการจอง</button>
      </div>
    </div>
  </div>
</template>
