import type { Config } from 'tailwindcss'

export default <Partial<Config>>{
  content: [
    './app/components/**/*.{vue,js,ts}',
    './app/pages/**/*.{vue,js,ts}',
    './app/layouts/**/*.{vue,js,ts}',
    './app/app.vue'
  ],
  theme: {
    extend: {
      colors: {
        bg: 'var(--bg)',
        surface: 'var(--surface)',
        'surface-muted': 'var(--surface-muted)',
        border: 'var(--border)',
        ink: 'var(--ink)',
        muted: 'var(--muted)',
        primary: {
          DEFAULT: 'var(--primary)',
          dark: 'var(--primary-dark)',
          soft: 'var(--primary-soft)'
        },
        wood: {
          DEFAULT: 'var(--wood)',
          dark: 'var(--wood-dark)'
        },
        reserved: {
          DEFAULT: 'var(--reserved)',
          soft: 'var(--reserved-soft)'
        },
        inuse: {
          DEFAULT: 'var(--inuse)',
          soft: 'var(--inuse-soft)'
        },
        overdue: {
          DEFAULT: 'var(--overdue)',
          soft: 'var(--overdue-soft)'
        },
        ok: {
          DEFAULT: 'var(--ok)',
          soft: 'var(--ok-soft)'
        }
      },
      fontFamily: {
        sans: ['Sarabun', 'sans-serif'],
        heading: ['Kanit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace']
      },
      borderRadius: {
        card: 'var(--radius)'
      },
      boxShadow: {
        card: 'var(--shadow)'
      }
    }
  }
}
