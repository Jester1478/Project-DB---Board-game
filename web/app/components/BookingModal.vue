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

const game = getGame(props.gameId)!
const firstFree = game.copies.find(c => copyStatus(c) === 'free')

const selectedCopyId = ref(firstFree?.id ?? game.copies[0].id)
const studentId = ref('')
const studentName = ref('')
const startTime = ref(fmtTime(simNow.value))
const endTime = ref(fmtTime(new Date(simNow.value.getTime() + 60 * 60000)))
const errorMessage = ref('')

function submit() {
  const [sh, sm] = startTime.value.split(':').map(Number)
  const [eh, em] = endTime.value.split(':').map(Number)
  const start = todayAt(sh, sm)
  const end = todayAt(eh, em)

  const { error } = addBooking({
    studentId: studentId.value.trim(),
    studentName: studentName.value.trim(),
    gameId: props.gameId,
    copyId: selectedCopyId.value,
    start,
    end
  })

  if (error) {
    errorMessage.value = error
    return
  }

  addToast(`จองสำเร็จ! ส่งอีเมลยืนยันให้ ${studentName.value.trim()} แล้ว`, false)
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
      <div class="field">
        <label>รหัสนิสิต</label>
        <input v-model="studentId" type="text" placeholder="เช่น 680XXXXX">
      </div>
      <div class="field">
        <label>ชื่อ-นามสกุล</label>
        <input v-model="studentName" type="text" placeholder="ชื่อผู้จอง">
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
