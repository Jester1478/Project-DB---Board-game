// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: false,
  experimental: {
    // Look for a newer deployment every minute instead of every hour, so an open
    // tab picks up a fix soon after it ships (see plugins/fresh-build.client.ts).
    checkOutdatedBuildInterval: 60 * 1000
  },
  modules: ['@nuxtjs/tailwindcss', '@nuxtjs/supabase'],
  tailwindcss: {
    cssPath: '~/assets/css/main.css'
  },
  supabase: {
    // No login flow in this app, so don't let the module redirect visitors to /login.
    redirect: false
  },
  app: {
    head: {
      title: 'ระบบจัดการสต๊อกคิวและการจองบอร์ดเกม',
      htmlAttrs: { lang: 'th' },
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Kanit:wght@400;500;600;700;800&family=Sarabun:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap'
        }
      ]
    }
  }
})
