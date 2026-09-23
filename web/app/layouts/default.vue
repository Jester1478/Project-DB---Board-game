<template>
  <div class="app-shell">
    <SiteHeader />
    <slot />
    <footer>
      ระบบจัดการคิวและการจองบอร์ดเกม
      <span class="sep">·</span>
      <NuxtLink to="/employee/login" class="staff-link">สำหรับเจ้าหน้าที่</NuxtLink>
    </footer>
  </div>
</template>
