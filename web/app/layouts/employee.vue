<script setup lang="ts">
import { useEmployeeAuth } from '~/composables/useEmployeeAuth'

const { employee, signOut } = useEmployeeAuth()

async function logout() {
  await signOut()
  await navigateTo('/employee/login')
}
</script>

<template>
  <div class="app-shell">
    <header class="top">
      <NuxtLink to="/employee" class="brand">
        <div class="mark">🧑‍💼</div>
        <div class="titles">
          <h1>ระบบเจ้าหน้าที่</h1>
          <p>จัดการการส่งมอบและรับคืนบอร์ดเกม</p>
        </div>
      </NuxtLink>
      <div v-if="employee" class="header-right">
        <span class="employee-who">
          {{ employee.firstName }} {{ employee.lastName }}<br>
          <span class="mono dim">{{ employee.email }}</span>
        </span>
        <button class="btn btn-ghost btn-sm" @click="logout">ออกจากระบบ</button>
      </div>
    </header>
    <slot />
  </div>
</template>
