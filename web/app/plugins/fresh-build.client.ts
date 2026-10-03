/**
 * A tab left open keeps running the JavaScript it loaded, however many times the
 * site has been deployed since — so a fix can be live and still not reach someone
 * who never closed the page. Nuxt already reloads on the next navigation once it
 * notices a new build; this covers the person who stays put on one page.
 */
export default defineNuxtPlugin(nuxtApp => {
  if (import.meta.dev) return

  const running = useRuntimeConfig().app.buildId
  let outdated = false

  /** Reloading would throw away whatever is being typed, so those pages wait. */
  function busy() {
    return !!document.querySelector('.overlay.show, main form')
  }

  function reloadIfIdle() {
    if (outdated && !busy()) reloadNuxtApp({ persistState: true })
  }

  async function check() {
    if (outdated) return reloadIfIdle()
    try {
      const latest = await $fetch<{ id: string }>(`/_nuxt/builds/latest.json?${Date.now()}`)
      outdated = latest.id !== running
    } catch {
      return  // offline, or mid-deploy: try again next time
    }
    reloadIfIdle()
  }

  nuxtApp.hook('app:manifest:update', () => {
    outdated = true
    reloadIfIdle()
  })

  // Coming back to the tab is the moment a stale page is most likely to be used.
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') void check()
  })
  useRouter().afterEach(() => { void check() })
})
