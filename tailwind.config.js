/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
    "./public/index.html",
    "./*.{js,jsx}"
  ],
  theme: {
    extend: {
      // K-pop inspired color palette
      colors: {
        // Stan purple gradient shades
        'stan-purple': {
          50: '#f3f1ff',
          100: '#ebe5ff',
          200: '#d9ccff',
          300: '#bea6ff',
          400: '#9f75ff',
          500: '#8b5cf6', // Primary purple
          600: '#7c3aed',
          700: '#6d28d9',
          800: '#5b21b6',
          900: '#4c1d95',
        },
        
        // Stan pink gradient shades  
        'stan-pink': {
          50: '#fdf2f8',
          100: '#fce7f3',
          200: '#fbcfe8',
          300: '#f9a8d4',
          400: '#f472b6',
          500: '#ec4899', // Primary pink
          600: '#db2777',
          700: '#be185d',
          800: '#9d174d',
          900: '#831843',
        },
        
        // Achievement colors
        'achievement': {
          gold: '#f59e0b',
          'gold-light': '#fbbf24',
          silver: '#6b7280',
          bronze: '#92400e'
        },
        
        // Emotional state colors
        encouraging: '#10b981',
        supportive: '#06b6d4',
        'gentle-warning': '#f59e0b',
        understanding: '#8b5cf6',
        
        // Enhanced grays with K-pop feel
        'kpop-gray': {
          50: '#fafafb',
          100: '#f4f4f6',
          200: '#e5e7eb',
          300: '#d1d5db',
          400: '#9ca3af',
          500: '#6b7280',
          600: '#4b5563',
          700: '#374151',
          800: '#1f2937',
          900: '#111827'
        }
      },
      
      // Custom gradients for backgrounds and components
      backgroundImage: {
        'stan-gradient': 'linear-gradient(135deg, #8b5cf6 0%, #a855f7 100%)',
        'stan-pink-gradient': 'linear-gradient(135deg, #ec4899 0%, #f472b6 100%)',
        'achievement-gradient': 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
        'encouraging-gradient': 'linear-gradient(135deg, #10b981 0%, #34d399 100%)',
        'supportive-gradient': 'linear-gradient(135deg, #06b6d4 0%, #38bdf8 100%)',
        'warning-gradient': 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
        'sparkle-mesh': `
          radial-gradient(circle at 20% 80%, rgba(139, 92, 246, 0.15) 0%, transparent 50%),
          radial-gradient(circle at 80% 20%, rgba(236, 72, 153, 0.15) 0%, transparent 50%),
          radial-gradient(circle at 40% 40%, rgba(16, 185, 129, 0.1) 0%, transparent 50%)
        `,
        'glass-effect': 'linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%)'
      },
      
      // Typography scale optimized for mobile K-pop aesthetic
      fontSize: {
        'display-large': ['32px', { lineHeight: '40px', fontWeight: '700' }],
        'display-small': ['24px', { lineHeight: '32px', fontWeight: '600' }],
        'h1': ['20px', { lineHeight: '28px', fontWeight: '600' }],
        'h2': ['18px', { lineHeight: '24px', fontWeight: '600' }], 
        'h3': ['16px', { lineHeight: '24px', fontWeight: '500' }],
        'body-large': ['16px', { lineHeight: '24px', fontWeight: '400' }],
        'body-small': ['14px', { lineHeight: '20px', fontWeight: '400' }],
        'caption': ['12px', { lineHeight: '16px', fontWeight: '500' }],
        'button': ['16px', { lineHeight: '20px', fontWeight: '600' }],
        'input': ['16px', { lineHeight: '20px', fontWeight: '400' }],
      },
      
      // Spacing system based on 4px/8px grid
      spacing: {
        '18': '4.5rem', // 72px - perfect for headers
        '22': '5.5rem', // 88px - bottom navigation height
        '30': '7.5rem', // 120px - input section height
        '60': '15rem',  // 240px - visualization height
        '40': '10rem'   // 160px - result section height
      },
      
      // Border radius for K-pop aesthetic
      borderRadius: {
        'xl': '12px',
        '2xl': '16px',
        '3xl': '20px',
        '4xl': '24px'
      },
      
      // Box shadows for depth and floating effects
      boxShadow: {
        'stan': '0 8px 32px rgba(139, 92, 246, 0.15)',
        'stan-hover': '0 12px 40px rgba(139, 92, 246, 0.25)',
        'stan-pink': '0 4px 16px rgba(236, 72, 153, 0.4)',
        'encouraging': '0 8px 32px rgba(16, 185, 129, 0.3)',
        'supportive': '0 8px 32px rgba(6, 182, 212, 0.3)',
        'warning': '0 8px 32px rgba(245, 158, 11, 0.3)',
        'card': '0 4px 20px rgba(0, 0, 0, 0.08)',
        'float': '0 8px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
        'glow': '0 0 20px rgba(139, 92, 246, 0.4)'
      },
      
      // Animation and transitions
      animation: {
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'bounce-in': 'bounceIn 0.5s ease-out',
        'progress-fill': 'progressFill 1s ease-out 0.5s both',
        'sparkle': 'sparkle 0.6s ease-out',
        'float': 'float 6s ease-in-out infinite',
        'pulse-gentle': 'pulseGentle 2s ease-in-out infinite'
      },
      
      // Custom keyframes
      keyframes: {
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(20px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' }
        },
        bounceIn: {
          '0%': { opacity: '0', transform: 'scale(0.8)' },
          '50%': { transform: 'scale(1.05)' },
          '100%': { opacity: '1', transform: 'scale(1)' }
        },
        progressFill: {
          '0%': { strokeDashoffset: '100%' },
          '100%': { strokeDashoffset: '0%' }
        },
        sparkle: {
          '0%, 100%': { opacity: '0', transform: 'scale(0)' },
          '50%': { opacity: '1', transform: 'scale(1)' }
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' }
        },
        pulseGentle: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' }
        }
      },
      
      // Backdrop blur for glass morphism
      backdropBlur: {
        'xs': '2px',
        'sm': '4px',
        'md': '12px',
        'lg': '16px',
        'xl': '24px'
      }
    },
  },
  plugins: [
    // Plugin for additional utilities
    function({ addUtilities, theme }) {
      const newUtilities = {
        // Glass morphism utilities
        '.glass': {
          background: 'rgba(255, 255, 255, 0.1)',
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255, 255, 255, 0.2)'
        },
        '.glass-dark': {
          background: 'rgba(139, 92, 246, 0.1)',
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(139, 92, 246, 0.2)'
        },
        
        // Gradient text utilities
        '.text-gradient-stan': {
          background: 'linear-gradient(135deg, #8b5cf6 0%, #ec4899 100%)',
          '-webkit-background-clip': 'text',
          '-webkit-text-fill-color': 'transparent',
          'background-clip': 'text'
        },
        
        // Achievement badge styles
        '.badge-achievement': {
          background: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
          color: 'white',
          padding: '8px 16px',
          borderRadius: '20px',
          fontSize: '14px',
          fontWeight: '600',
          display: 'inline-flex',
          alignItems: 'center',
          gap: '4px',
          boxShadow: '0 4px 12px rgba(245, 158, 11, 0.3)'
        },
        
        // Button variants
        '.btn-stan': {
          background: 'linear-gradient(135deg, #8b5cf6 0%, #a855f7 100%)',
          color: 'white',
          border: 'none',
          borderRadius: '12px',
          padding: '12px 24px',
          fontSize: '16px',
          fontWeight: '600',
          boxShadow: '0 4px 16px rgba(139, 92, 246, 0.3)',
          transition: 'all 0.2s ease',
          cursor: 'pointer'
        },
        '.btn-stan:hover': {
          transform: 'translateY(-1px)',
          boxShadow: '0 6px 20px rgba(139, 92, 246, 0.4)'
        },
        '.btn-stan:active': {
          transform: 'translateY(1px)',
          boxShadow: '0 2px 8px rgba(139, 92, 246, 0.4)'
        },
        
        // Progress ring utilities
        '.progress-ring': {
          transform: 'rotate(-90deg)',
          transition: 'stroke-dashoffset 1s ease-out'
        },
        
        // Thumb-friendly touch targets
        '.touch-target': {
          minHeight: '44px',
          minWidth: '44px'
        },
        
        // Card hover effects
        '.card-hover': {
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          cursor: 'pointer'
        },
        '.card-hover:hover': {
          transform: 'translateY(-2px)',
          boxShadow: '0 8px 30px rgba(0, 0, 0, 0.12)'
        }
      };
      
      addUtilities(newUtilities);
    }
  ],
};