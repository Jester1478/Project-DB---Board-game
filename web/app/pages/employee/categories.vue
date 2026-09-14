<script setup lang="ts">
import { ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Category } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const { categories, loading, loadError, categoryGameCount, createCategory, deleteCategory } = useBoardGameStore()
const { addToast } = useToasts()

const newName = ref('')
const errorMessage = ref('')
const busy = ref(false)

async function add() {
  if (busy.value) return
  errorMessage.value = ''
  busy.value = true
  const name = newName.value.trim()
  const { error } = await createCategory(name)
  busy.value = false
  if (error) {
    errorMessage.value = error
    return
  }
  newName.value = ''
  addToast(`เพิ่มหมวดหมู่ "${name}" แล้ว`, false)
}

async function remove(category: Category) {
  if (busy.value) return
  const count = categoryGameCount(category.id)
  const effect = count
    ? `\nเกม ${count} เกมในหมวดนี้จะไม่ถูกลบ แค่ถูกเอาออกจากหมวดหมู่นี้`
    : ''
  if (!confirm(`ลบหมวดหมู่ "${category.name}"?${effect}`)) return

  busy.value = true
  const { error } = await deleteCategory(category.id)
  busy.value = false
  addToast(error ?? `ลบหมวดหมู่ "${category.name}" แล้ว`, !!error)
}
</script>

<template>
  <main>
    <div class="section-head">
      <h2>หมวดหมู่</h2>
      <p>เพิ่มหรือลบหมวดหมู่เกม เลือกหมวดหมู่ให้แต่ละเกมได้ที่หน้าแก้ไขเกม</p>
    </div>

    <form class="panel form-panel" @submit.prevent="add">
      <div v-if="errorMessage" class="err">{{ errorMessage }}</div>
      <div class="inline-form">
        <input v-model="newName" type="text" maxlength="100" placeholder="ชื่อหมวดหมู่ใหม่ เช่น Card Game" aria-label="ชื่อหมวดหมู่ใหม่">
        <button class="btn btn-primary btn-sm" type="submit" :disabled="busy || !newName.trim()">+ เพิ่มหมวดหมู่</button>
      </div>
    </form>

    <p v-if="loadError" class="err">โหลดข้อมูลไม่สำเร็จ: {{ loadError }}</p>

    <table class="book-table">
      <thead>
        <tr><th>หมวดหมู่</th><th>จำนวนเกม</th><th /></tr>
      </thead>
      <tbody>
        <tr v-for="c in categories" :key="c.id">
          <td>{{ c.name }}</td>
          <td>{{ categoryGameCount(c.id) }} เกม</td>
          <td class="cell-right">
            <button class="btn btn-ghost btn-sm" type="button" :disabled="busy" @click="remove(c)">ลบ</button>
          </td>
        </tr>
        <tr v-if="!categories.length">
          <td colspan="3" class="empty-row">{{ loading ? 'กำลังโหลด...' : 'ยังไม่มีหมวดหมู่' }}</td>
        </tr>
      </tbody>
    </table>
  </main>
</template>
