# "Should I Buy This?" Calculator Integration Guide

## 🚀 Quick Start

### Basic Implementation
```jsx
import ShouldIBuyCalculator from './ShouldIBuyCalculator';
import calculatorUtils from './calculatorUtils';

// In your main app component
function App() {
  const [showCalculator, setShowCalculator] = useState(false);
  
  return (
    <div className="app">
      {showCalculator ? (
        <ShouldIBuyCalculator 
          onClose={() => setShowCalculator(false)}
          userProfile={userProfile}
        />
      ) : (
        <YourMainApp />
      )}
    </div>
  );
}
```

### Enhanced Props Version
```jsx
<ShouldIBuyCalculator
  userProfile={{
    monthlyBudget: 500,
    currentSavings: 1200,
    goals: [
      { id: 1, title: "NewJeans Concert", current: 180, target: 250, emoji: "🎵" },
      { id: 2, title: "BTS Merch", current: 85, target: 120, emoji: "💜" },
      { id: 3, title: "Emergency Fund", current: 300, target: 500, emoji: "⭐" }
    ],
    recentPurchases: [
      { amount: 25, date: '2024-01-15', category: 'merch' },
      { amount: 50, date: '2024-01-10', category: 'albums' }
    ],
    payDates: [1, 15], // 1st and 15th of month
    billDates: [5, 20] // 5th and 20th of month
  }}
  onSaveDecision={(decision) => saveToHistory(decision)}
  onShare={(data) => shareToSocial(data)}
  theme="purple" // or "pink", "gradient"
/>
```

## 🎨 Theming Options

### Custom Color Schemes
```jsx
// Purple theme (default)
<ShouldIBuyCalculator theme="purple" />

// Pink theme for different vibes
<ShouldIBuyCalculator theme="pink" />

// Custom colors
<ShouldIBuyCalculator 
  customColors={{
    primary: "#8b5cf6",
    secondary: "#ec4899",
    success: "#10b981",
    warning: "#f59e0b",
    background: "#fafafb"
  }}
/>
```

### Dark Mode Support
```jsx
<ShouldIBuyCalculator 
  darkMode={true}
  theme="purple"
/>
```

## 📱 Advanced Features

### Camera Integration (OCR)
```jsx
// Install dependencies
// npm install react-camera-pro tesseract.js

import { Camera } from 'react-camera-pro';
import Tesseract from 'tesseract.js';

const CameraScanFeature = ({ onPriceDetected }) => {
  const scanReceipt = async (image) => {
    try {
      const { data: { text } } = await Tesseract.recognize(image, 'eng');
      const priceRegex = /\$(\d+(?:\.\d{2})?)/g;
      const prices = text.match(priceRegex);
      
      if (prices && prices.length > 0) {
        onPriceDetected(parseFloat(prices[0].replace('$', '')));
      }
    } catch (error) {
      console.error('OCR failed:', error);
    }
  };
  
  return (
    <Camera 
      onTakePhoto={(dataUri) => scanReceipt(dataUri)}
      idealFacingMode="environment"
    />
  );
};
```

### Voice Input Integration
```jsx
// Install dependencies
// npm install react-speech-recognition

import SpeechRecognition, { useSpeechRecognition } from 'react-speech-recognition';

const VoiceInputFeature = ({ onPriceDetected }) => {
  const {
    transcript,
    listening,
    resetTranscript,
    browserSupportsSpeechRecognition
  } = useSpeechRecognition();

  useEffect(() => {
    const priceMatch = transcript.match(/(\d+)\s*dollars?/i);
    if (priceMatch) {
      onPriceDetected(parseInt(priceMatch[1]));
      resetTranscript();
    }
  }, [transcript]);

  return (
    <button 
      onClick={() => SpeechRecognition.startListening()}
      className="voice-input-btn"
    >
      {listening ? '🎤 Listening...' : '🎙️ Say Price'}
    </button>
  );
};
```

## 🔧 Customization Examples

### Custom Goal Types
```jsx
const customGoalTypes = {
  concert: { emoji: "🎵", color: "#ec4899", category: "Experience" },
  merch: { emoji: "💜", color: "#8b5cf6", category: "Collection" },
  emergency: { emoji: "⭐", color: "#10b981", category: "Security" },
  album: { emoji: "💿", color: "#f59e0b", category: "Music" },
  fashion: { emoji: "👗", color: "#06b6d4", category: "Style" }
};

<ShouldIBuyCalculator 
  goalTypes={customGoalTypes}
  userProfile={userProfile}
/>
```

### Custom Messages & Language
```jsx
const customMessages = {
  'go-for-it': [
    "SLAY! This fits your budget perfectly! 👑",
    "Your wallet AND your goals are happy! ✨",
    "Stan responsibly achieved! 💜"
  ],
  'maybe-wait': [
    "Patience is a stan virtue! Almost there! 💪",
    "Your future concert self will thank you! 🎵",
    "Building that financial glow-up! ⭐"
  ],
  'save-more': [
    "CEO of delayed gratification! 📈",
    "This is how legends are made! 👑",
    "Your discipline is absolutely iconic! 💎"
  ]
};

<ShouldIBuyCalculator 
  customMessages={customMessages}
  language="en" // Support for "ko", "jp", etc.
/>
```

## 🎯 Analytics Integration

### Track User Decisions
```jsx
import { analytics } from './analytics';

const trackCalculatorUsage = (decision) => {
  analytics.track('Purchase Decision Made', {
    amount: decision.amount,
    recommendation: decision.type,
    goals_impacted: decision.goalsAffected.length,
    user_followed_advice: decision.userAction === decision.recommendation,
    timestamp: new Date().toISOString()
  });
};

<ShouldIBuyCalculator 
  onSaveDecision={trackCalculatorUsage}
  userProfile={userProfile}
/>
```

### A/B Testing Different Messages
```jsx
const experimentVariant = useABTest('calculator-messages');

const messageVariants = {
  supportive: supportiveMessages,
  playful: playfulMessages,
  direct: directMessages
};

<ShouldIBuyCalculator 
  customMessages={messageVariants[experimentVariant]}
  userProfile={userProfile}
/>
```

## 🔄 State Management Integration

### Redux Integration
```jsx
import { useSelector, useDispatch } from 'react-redux';
import { saveDecision, updateUserProfile } from './store/slices/userSlice';

const CalculatorContainer = () => {
  const dispatch = useDispatch();
  const userProfile = useSelector(state => state.user.profile);
  const calculatorHistory = useSelector(state => state.user.calculatorHistory);
  
  const handleSaveDecision = (decision) => {
    dispatch(saveDecision(decision));
    
    // Update user profile based on decision
    if (decision.userAction === 'purchased') {
      dispatch(updateUserProfile({
        currentSavings: userProfile.currentSavings - decision.amount
      }));
    }
  };
  
  return (
    <ShouldIBuyCalculator 
      userProfile={userProfile}
      onSaveDecision={handleSaveDecision}
      history={calculatorHistory}
    />
  );
};
```

### Context API Integration
```jsx
import { createContext, useContext, useState } from 'react';

const FinancialContext = createContext();

export const useFinancial = () => useContext(FinancialContext);

export const FinancialProvider = ({ children }) => {
  const [userProfile, setUserProfile] = useState(initialProfile);
  const [decisions, setDecisions] = useState([]);
  
  const addDecision = (decision) => {
    setDecisions(prev => [decision, ...prev]);
    
    // Update user profile
    if (decision.userAction === 'purchased') {
      setUserProfile(prev => ({
        ...prev,
        currentSavings: prev.currentSavings - decision.amount,
        recentPurchases: [
          { amount: decision.amount, date: new Date().toISOString() },
          ...prev.recentPurchases.slice(0, 9) // Keep last 10
        ]
      }));
    }
  };
  
  return (
    <FinancialContext.Provider value={{
      userProfile,
      decisions,
      addDecision,
      updateProfile: setUserProfile
    }}>
      {children}
    </FinancialContext.Provider>
  );
};
```

## 📊 Performance Optimizations

### Lazy Loading
```jsx
import { lazy, Suspense } from 'react';

const ShouldIBuyCalculator = lazy(() => import('./ShouldIBuyCalculator'));

function App() {
  return (
    <Suspense fallback={<CalculatorSkeleton />}>
      <ShouldIBuyCalculator userProfile={userProfile} />
    </Suspense>
  );
}

const CalculatorSkeleton = () => (
  <div className="animate-pulse bg-gradient-to-b from-purple-500 to-pink-500 min-h-screen">
    <div className="h-18 bg-white bg-opacity-20" />
    <div className="p-5 space-y-4">
      <div className="h-14 bg-white bg-opacity-20 rounded-2xl" />
      <div className="flex gap-2">
        {[1,2,3,4,5].map(i => (
          <div key={i} className="h-8 w-16 bg-white bg-opacity-20 rounded-2xl" />
        ))}
      </div>
    </div>
  </div>
);
```

### Memoization for Heavy Calculations
```jsx
import { useMemo, useCallback } from 'react';
import { calculatePurchaseImpact } from './calculatorUtils';

const OptimizedCalculator = ({ userProfile, price }) => {
  const impact = useMemo(() => {
    if (!price) return null;
    return calculatePurchaseImpact(parseFloat(price), userProfile);
  }, [price, userProfile]);
  
  const handleSave = useCallback((decision) => {
    // Memoized to prevent unnecessary re-renders
    saveToStorage(decision);
  }, []);
  
  return (
    <ShouldIBuyCalculator 
      preCalculatedImpact={impact}
      onSave={handleSave}
    />
  );
};
```

## 🎪 Animation Customization

### Custom Animation Timings
```jsx
<ShouldIBuyCalculator 
  animationConfig={{
    progressDuration: 1200,
    staggerDelay: 200,
    bounceIntensity: 0.8,
    enableSparkles: true,
    celebrationDuration: 2000
  }}
/>
```

### Reduced Motion Support
```jsx
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

<ShouldIBuyCalculator 
  animationConfig={{
    respectReducedMotion: true,
    fallbackToFade: prefersReducedMotion
  }}
/>
```

## 🌍 Internationalization

### Multi-language Support
```jsx
import i18n from './i18n';

const translations = {
  en: {
    title: "Should I Buy This? 💜",
    goForIt: "✨ Go For It!",
    maybeWait: "🤔 Maybe Wait?",
    saveMore: "💙 Trust The Process"
  },
  ko: {
    title: "이거 사도 될까? 💜",
    goForIt: "✨ 사도 돼!",
    maybeWait: "🤔 조금만 기다려?",
    saveMore: "💙 미래를 믿어"
  }
};

<ShouldIBuyCalculator 
  translations={translations[i18n.language]}
  locale={i18n.language}
/>
```

## 🔐 Security Considerations

### Data Privacy
```jsx
// Ensure sensitive financial data is handled securely
const secureUserProfile = {
  ...userProfile,
  // Remove or encrypt sensitive fields
  accountNumbers: undefined,
  ssn: undefined,
  // Hash or anonymize if needed
  userId: hashUserId(userProfile.id)
};

<ShouldIBuyCalculator 
  userProfile={secureUserProfile}
  enableDataCollection={userConsent.analytics}
  encryptDecisions={true}
/>
```

### Input Validation
```jsx
import { validatePurchaseAmount } from './validation';

const SafeCalculatorWrapper = ({ children }) => {
  const [error, setError] = useState(null);
  
  const handlePriceChange = (price) => {
    try {
      validatePurchaseAmount(price);
      setError(null);
    } catch (err) {
      setError(err.message);
    }
  };
  
  return (
    <div>
      {error && <ErrorMessage message={error} />}
      <ShouldIBuyCalculator onPriceChange={handlePriceChange} />
    </div>
  );
};
```

## 📈 Success Metrics to Track

### User Engagement
- Time spent in calculator
- Completion rate (price entered → decision made)
- Return usage frequency
- Social sharing rate

### Financial Impact
- Money saved through "wait" recommendations
- Goal completion acceleration
- User-reported satisfaction with decisions
- Long-term budgeting improvement

### Technical Performance
- Load time on mobile devices
- Animation smoothness (FPS)
- Memory usage during heavy calculations
- Battery impact on mobile

## 🎁 Ready-to-Use Examples

### Minimal Setup
```jsx
// App.jsx
import ShouldIBuyCalculator from './ShouldIBuyCalculator';

export default function App() {
  const mockUser = {
    monthlyBudget: 300,
    currentSavings: 800,
    goals: [
      { id: 1, title: "Concert Tickets", current: 120, target: 200, emoji: "🎵" }
    ]
  };
  
  return <ShouldIBuyCalculator userProfile={mockUser} />;
}
```

### Full-Featured Setup
```jsx
// AdvancedApp.jsx
import React, { useState, useEffect } from 'react';
import ShouldIBuyCalculator from './ShouldIBuyCalculator';
import { FinancialProvider } from './context/FinancialContext';
import { trackEvent } from './analytics';

export default function AdvancedApp() {
  const [showCalculator, setShowCalculator] = useState(false);
  const [userProfile, setUserProfile] = useState(null);
  
  useEffect(() => {
    // Load user data
    loadUserProfile().then(setUserProfile);
  }, []);
  
  const handleDecision = async (decision) => {
    await saveDecision(decision);
    trackEvent('calculator_decision', decision);
    
    if (decision.recommendation === 'go-for-it' && decision.userAction === 'saved') {
      // User saved money - celebrate!
      showSuccessAnimation();
    }
  };
  
  if (!userProfile) return <LoadingSpinner />;
  
  return (
    <FinancialProvider>
      <div className="app">
        <button 
          onClick={() => setShowCalculator(true)}
          className="btn-stan"
        >
          Should I Buy This? 💜
        </button>
        
        {showCalculator && (
          <ShouldIBuyCalculator
            userProfile={userProfile}
            onClose={() => setShowCalculator(false)}
            onSaveDecision={handleDecision}
            enableVoiceInput
            enableCameraScan
            theme="gradient"
          />
        )}
      </div>
    </FinancialProvider>
  );
}
```

This calculator transforms the stressful "should I buy this?" moment into an empowering, celebratory experience that K-pop fans will love to use and share! 🌟