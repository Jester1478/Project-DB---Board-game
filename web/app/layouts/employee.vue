<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useEmployeeAuth } from '~/composables/useEmployeeAuth'

const { employee, signOut } = useEmployeeAuth()
const route = useRoute()

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
          <p>จัดการการส่งมอบ รับคืน และสต๊อกบอร์ดเกม</p>
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
    <nav v-if="employee" class="employee-tabs">
      <NuxtLink to="/employee" :class="{ active: route.path === '/employee' }">การจอง</NuxtLink>
      <NuxtLink to="/employee/games" :class="{ active: route.path.startsWith('/employee/games') }">จัดการเกม</NuxtLink>
      <NuxtLink to="/employee/categories" :class="{ active: route.path.startsWith('/employee/categories') }">หมวดหมู่</NuxtLink>
    </nav>
    <slot />
  </div>
</template>
