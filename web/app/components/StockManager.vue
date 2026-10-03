<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { CONDITION_LABELS, MAX_COPIES_PER_ADD, isUsableCopy, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Copy, CopyCondition } from '~/composables/useBoardGameStore'

const props = defineProps<{ gameId: string }>()

const { getGame, addCopies, setCopyCondition, deleteCopy, copyHasHistory, activeBookingCount } = useBoardGameStore()

const game = computed(() => getGame(props.gameId))
const copies = computed(() => [...(game.value?.copies ?? [])].sort((a, b) => a.number - b.number))
const conditions = Object.keys(CONDITION_LABELS) as CopyCondition[]

/**
 * Nothing here writes to the database. These hold what the employee has asked for
 * until the page's save button calls apply(), so the whole page commits at once.
 */
const addCount = ref(0)
const newCondition = reactive<Record<string, CopyCondition>>({})
const removing = ref<string[]>([])

const pendingAdd = computed(() => Math.max(0, Number(addCount.value) || 0))
const conditionOf = (c: Copy) => newCondition[c.id] ?? c.condition
const isRemoving = (c: Copy) => removing.value.includes(c.id)
const usableAfter = (c: Copy) => isUsableCopy({ ...c, condition: conditionOf(c) })

function toggleRemove(c: Copy) {
  removing.value = isRemoving(c) ? removing.value.filter(id => id !== c.id) : [...removing.value, c.id]
}

function setCondition(c: Copy, value: string) {
  const next = value as CopyCondition
  if (next === c.condition) delete newCondition[c.id]
  else newCondition[c.id] = next
}

const totalAfter = computed(() => copies.value.length - removing.value.length + pendingAdd.value)
const usableCount = computed(() =>
  copies.value.filter(c => !isRemoving(c) && usableAfter(c)).length + pendingAdd.value)

/** Plain-language list of what save would do, shown in the page's save bar. */
const changeSummary = computed(() => {
  const parts: string[] = []
  if (pendingAdd.value) parts.push(`เพิ่ม ${pendingAdd.value} กล่อง`)
  const changed = Object.keys(newCondition).filter(id => !removing.value.includes(id)).length
  if (changed) parts.push(`เปลี่ยนสภาพ ${changed} กล่อง`)
  if (removing.value.length) parts.push(`ลบ ${removing.value.length} กล่อง`)
  return parts
})

function reset() {
  addCount.value = 0
  removing.value = []
  Object.keys(newCondition).forEach(k => delete newCondition[k])
}

/**
 * Runs the staged changes. Each box is its own row in game_copy with its own
 * constraints, so they go one at a time and the first problem stops the rest.
 */
async function apply(): Promise<string | null> {
  for (const [copyId, condition] of Object.entries(newCondition)) {
    if (removing.value.includes(copyId)) continue  // about to be deleted anyway
    const { error } = await setCopyCondition(copyId, condition)
    if (error) return error
  }
  for (const copyId of removing.value) {
    const { error } = await deleteCopy(copyId)
    if (error) return error
  }
  if (pendingAdd.value) {
    const { error } = await addCopies(props.gameId, pendingAdd.value)
    if (error) return error
  }
  reset()
  return null
}

defineExpose({ changeSummary, apply, reset })
</script>

<template>
  <section v-if="game" class="panel form-panel">
    <div class="stock-head">
      <div>
        <h3>สต๊อกกล่อง</h3>
        <p class="dim-text">
          พร้อมให้บริการ {{ usableCount }} จาก {{ totalAfter }} กล่อง
          <span v-if="changeSummary.length">(หลังกดบันทึก)</span>
        </p>
      </div>
      <div class="stock-add">
        <label for="add-copies">เพิ่มกล่องใหม่</label>
        <input id="add-copies" v-model.number="addCount" type="number" min="0" :max="MAX_COPIES_PER_ADD" step="1">
      </div>
    </div>

    <table class="book-table stock-table">
      <thead>
        <tr><th>รหัสกล่อง</th><th>สภาพ</th><th>การจองที่ยังไม่จบ</th><th /></tr>
      </thead>
      <tbody>
        <tr
          v-for="c in copies"
          :key="c.id"
          :class="{ retired: !usableAfter(c), 'row-removing': isRemoving(c) }"
        >
          <td class="mono">{{ c.label }}</td>
          <td>
            <select
              class="cond-select"
              :value="conditionOf(c)"
              :disabled="isRemoving(c)"
              @change="setCondition(c, ($event.target as HTMLSelectElement).value)"
            >
              <option v-for="k in conditions" :key="k" :value="k">{{ CONDITION_LABELS[k] }}</option>
            </select>
          </td>
          <td>{{ activeBookingCount(c.id) }}</td>
          <td class="cell-right">
            <button
              class="btn btn-ghost btn-sm"
              type="button"
              :disabled="copyHasHistory(c.id)"
              :title="copyHasHistory(c.id) ? 'มีประวัติการจองแล้ว ลบไม่ได้ ให้เปลี่ยนสภาพแทน' : ''"
              @click="toggleRemove(c)"
            >
              {{ isRemoving(c) ? 'ยกเลิกการลบ' : 'ลบ' }}
            </button>
          </td>
        </tr>
        <tr v-if="pendingAdd" class="row-adding">
          <td class="mono">+ {{ pendingAdd }} กล่องใหม่</td>
          <td>{{ CONDITION_LABELS.Good }}</td>
          <td>0</td>
          <td class="cell-right">
            <button class="btn btn-ghost btn-sm" type="button" @click="addCount = 0">ยกเลิก</button>
          </td>
        </tr>
        <tr v-if="!copies.length && !pendingAdd">
          <td colspan="4" class="empty-row">ยังไม่มีกล่องในสต๊อก</td>
        </tr>
      </tbody>
    </table>

    <p class="hint stock-hint">
      กล่องที่เคยมีการจองลบไม่ได้ เพราะต้องเก็บประวัติไว้ ถ้าจะเลิกให้บริการ ให้เปลี่ยนสภาพเป็น "ชำรุด" หรือ "สูญหาย" ลูกค้าจะไม่เห็นกล่องนั้นอีก
    </p>
  </section>
</template>
