<script setup lang="ts">
import { computed, ref } from 'vue'
import { CONDITION_LABELS, MAX_COPIES_PER_ADD, isUsableCopy, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Copy, CopyCondition } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

const props = defineProps<{ gameId: string }>()

const { getGame, addCopies, setCopyCondition, deleteCopy, copyHasHistory, activeBookingCount } = useBoardGameStore()
const { addToast } = useToasts()

const game = computed(() => getGame(props.gameId))
const copies = computed(() => [...(game.value?.copies ?? [])].sort((a, b) => a.number - b.number))
const usableCount = computed(() => copies.value.filter(isUsableCopy).length)

const conditions = Object.keys(CONDITION_LABELS) as CopyCondition[]
const addCount = ref(1)
const busy = ref(false)

async function run(action: () => Promise<{ error: string | null }>, success: string) {
  if (busy.value) return false
  busy.value = true
  const { error } = await action()
  busy.value = false
  addToast(error ?? success, !!error)
  return !error
}

function onAdd() {
  const n = Number(addCount.value)
  void run(() => addCopies(props.gameId, n), `เพิ่มกล่องแล้ว ${n} กล่อง`)
}

async function onCondition(copy: Copy, event: Event) {
  const select = event.target as HTMLSelectElement
  const next = select.value as CopyCondition
  const ok = await run(() => setCopyCondition(copy.id, next), `เปลี่ยนสภาพ ${copy.label} เป็น "${CONDITION_LABELS[next]}" แล้ว`)
  // On failure the data didn't change, so put the dropdown back to what's really stored.
  if (!ok) select.value = copy.condition
}

function onDelete(copy: Copy) {
  if (!confirm(`ลบกล่อง ${copy.label} ออกจากสต๊อก?`)) return
  void run(() => deleteCopy(copy.id), `ลบกล่อง ${copy.label} แล้ว`)
}
</script>

<template>
  <section v-if="game" class="panel form-panel">
    <div class="stock-head">
      <div>
        <h3>สต๊อกกล่อง</h3>
        <p class="dim-text">พร้อมให้บริการ {{ usableCount }} จาก {{ copies.length }} กล่อง</p>
      </div>
      <div class="stock-add">
        <input v-model.number="addCount" type="number" min="1" :max="MAX_COPIES_PER_ADD" step="1" aria-label="จำนวนกล่องที่จะเพิ่ม">
        <button class="btn btn-primary btn-sm" type="button" :disabled="busy" @click="onAdd">+ เพิ่มกล่อง</button>
      </div>
    </div>

    <table class="book-table stock-table">
      <thead>
        <tr><th>รหัสกล่อง</th><th>สภาพ</th><th>การจองที่ยังไม่จบ</th><th /></tr>
      </thead>
      <tbody>
        <tr v-for="c in copies" :key="c.id" :class="{ retired: !isUsableCopy(c) }">
          <td class="mono">{{ c.label }}</td>
          <td>
            <select class="cond-select" :value="c.condition" :disabled="busy" @change="onCondition(c, $event)">
              <option v-for="k in conditions" :key="k" :value="k">{{ CONDITION_LABELS[k] }}</option>
            </select>
          </td>
          <td>{{ activeBookingCount(c.id) }}</td>
          <td class="cell-right">
            <button
              class="btn btn-ghost btn-sm"
              type="button"
              :disabled="busy || copyHasHistory(c.id)"
              :title="copyHasHistory(c.id) ? 'มีประวัติการจองแล้ว ลบไม่ได้ ให้เปลี่ยนสภาพแทน' : ''"
              @click="onDelete(c)"
            >
              ลบ
            </button>
          </td>
        </tr>
        <tr v-if="!copies.length">
          <td colspan="4" class="empty-row">ยังไม่มีกล่องในสต๊อก</td>
        </tr>
      </tbody>
    </table>

    <p class="hint stock-hint">
      กล่องที่เคยมีการจองลบไม่ได้ เพราะต้องเก็บประวัติไว้ ถ้าจะเลิกให้บริการ ให้เปลี่ยนสภาพเป็น "ชำรุด" หรือ "สูญหาย" ลูกค้าจะไม่เห็นกล่องนั้นอีก
    </p>
  </section>
</template>
