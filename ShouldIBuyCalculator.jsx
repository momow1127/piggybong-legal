import React, { useState, useEffect } from 'react';
import { Camera, ArrowLeft, Sparkles, TrendingUp, Clock, Target, Heart, Share } from 'lucide-react';

const ShouldIBuyCalculator = () => {
  const [price, setPrice] = useState('');
  const [showResult, setShowResult] = useState(false);
  const [animationPhase, setAnimationPhase] = useState(0);
  
  // Mock user data - replace with actual data
  const userGoals = [
    { id: 1, title: "NewJeans Concert Tickets", current: 180, target: 250, emoji: "🎵" },
    { id: 2, title: "BTS Merch Collection", current: 85, target: 120, emoji: "💜" },
    { id: 3, title: "Emergency Stan Fund", current: 300, target: 500, emoji: "⭐" }
  ];

  const quickPresets = ['$5', '$10', '$25', '$50', '$100'];

  useEffect(() => {
    if (showResult) {
      const timer1 = setTimeout(() => setAnimationPhase(1), 300);
      const timer2 = setTimeout(() => setAnimationPhase(2), 800);
      const timer3 = setTimeout(() => setAnimationPhase(3), 1200);
      
      return () => {
        clearTimeout(timer1);
        clearTimeout(timer2);
        clearTimeout(timer3);
      };
    }
  }, [showResult]);

  const calculateImpact = () => {
    const amount = parseFloat(price) || 0;
    const totalBudget = 200; // Mock monthly budget
    const impactPercentage = (amount / totalBudget) * 100;
    
    if (impactPercentage <= 20) return 'go-for-it';
    if (impactPercentage <= 40) return 'maybe-wait';
    return 'save-more';
  };

  const getRecommendation = () => {
    const impact = calculateImpact();
    const messages = {
      'go-for-it': {
        badge: "✨ Go For It!",
        message: "You've got this! This fits perfectly in your stan budget 💜",
        badgeClass: "badge-go-for-it"
      },
      'maybe-wait': {
        badge: "🤔 Maybe Wait?",
        message: "Almost there! Maybe save for one more week? You're doing amazing! 💪",
        badgeClass: "badge-maybe-wait"
      },
      'save-more': {
        badge: "💙 Trust The Process",
        message: "Your future self will thank you for this patience. You're building something beautiful! 🌟",
        badgeClass: "badge-save-more"
      }
    };
    
    return messages[impact];
  };

  const handleCalculate = () => {
    if (price) {
      setAnimationPhase(0);
      setShowResult(true);
    }
  };

  const ProgressRing = ({ percentage, size = 60, strokeWidth = 4 }) => {
    const radius = (size - strokeWidth) / 2;
    const circumference = radius * 2 * Math.PI;
    const strokeDasharray = `${circumference} ${circumference}`;
    const strokeDashoffset = circumference - (percentage / 100) * circumference;

    return (
      <div className="relative inline-flex items-center justify-center">
        <svg width={size} height={size} className="transform -rotate-90">
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="currentColor"
            strokeWidth={strokeWidth}
            fill="transparent"
            className="text-gray-200"
          />
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="currentColor"
            strokeWidth={strokeWidth}
            fill="transparent"
            strokeDasharray={strokeDasharray}
            strokeDashoffset={strokeDashoffset}
            className="text-purple-500 transition-all duration-1000 ease-out"
            style={{ 
              strokeLinecap: 'round',
              transitionDelay: showResult ? '0.5s' : '0s'
            }}
          />
        </svg>
        <span className="absolute text-xs font-semibold text-gray-700">
          {Math.round(percentage)}%
        </span>
      </div>
    );
  };

  const GoalImpactItem = ({ goal, delay }) => {
    const currentAmount = parseFloat(price) || 0;
    const daysDelay = Math.ceil(currentAmount / 10); // Mock calculation
    const isPositive = currentAmount < 30;

    return (
      <div 
        className={`goal-impact-item ${isPositive ? 'accelerated' : 'delayed'}`}
        style={{ animationDelay: `${delay}ms` }}
      >
        <div className={`impact-icon ${isPositive ? 'bg-green-100 text-green-600' : 'bg-amber-100 text-amber-600'}`}>
          {goal.emoji}
        </div>
        <div className="impact-content">
          <div className="impact-title">{goal.title}</div>
          <div className="impact-description">
            {isPositive ? 'On track!' : `${daysDelay} days later`}
          </div>
        </div>
        <div className={`impact-change ${isPositive ? 'positive' : 'negative'}`}>
          {isPositive ? '+2 days' : `-${daysDelay} days`}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-purple-500 to-pink-500">
      {/* Header */}
      <div className="header">
        <ArrowLeft className="w-6 h-6 text-white" />
        <h1 className="title">Should I Buy This? 💜</h1>
        <Sparkles className="w-6 h-6 text-white" />
      </div>

      {/* Input Section */}
      <div className="input-section">
        <div className="price-input-wrapper">
          <input
            type="number"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="$0"
            className="price-input"
            autoFocus
          />
          <button className="camera-scan-btn">
            <Camera className="w-5 h-5" />
          </button>
        </div>
        
        <div className="presets-row">
          {quickPresets.map((preset) => (
            <button
              key={preset}
              onClick={() => setPrice(preset.replace('$', ''))}
              className="preset-btn"
            >
              {preset}
            </button>
          ))}
        </div>
        
        {price && !showResult && (
          <button
            onClick={handleCalculate}
            className="w-full mt-4 h-12 bg-white bg-opacity-90 text-purple-600 rounded-xl font-semibold text-lg transition-all duration-200 active:scale-95"
          >
            Calculate Impact ✨
          </button>
        )}
      </div>

      {/* Results Section */}
      {showResult && (
        <>
          {/* Impact Visualization */}
          <div className="impact-visualization">
            <div className="journey-header">
              <h2 className="journey-title">Your Fan Journey</h2>
              <p className="journey-subtitle">See how this affects your goals</p>
            </div>

            {/* Before/After Cards */}
            <div className="before-after-container">
              <div className="progress-card">
                <div className="card-label">Before</div>
                <div className="progress-ring">
                  <ProgressRing percentage={72} />
                </div>
                <div className="goal-title">Concert Fund</div>
                <div className="goal-progress">$180 / $250</div>
              </div>
              
              <div className="progress-card">
                <div className="card-label">After</div>
                <div className="progress-ring">
                  <ProgressRing percentage={Math.max(72 - (parseFloat(price) || 0) / 250 * 100, 0)} />
                </div>
                <div className="goal-title">Concert Fund</div>
                <div className="goal-progress">
                  ${Math.max(180 - (parseFloat(price) || 0), 0)} / $250
                </div>
              </div>
            </div>

            {/* Goal Impact List */}
            {animationPhase >= 1 && (
              <div className="goal-impact-list">
                {userGoals.map((goal, index) => (
                  <GoalImpactItem 
                    key={goal.id} 
                    goal={goal} 
                    delay={index * 150}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Decision Result */}
          {animationPhase >= 2 && (
            <div className="decision-result">
              <div className={`recommendation-badge ${getRecommendation().badgeClass}`}>
                {getRecommendation().badge}
              </div>
              <p className="supporting-message">
                {getRecommendation().message}
              </p>
              
              {animationPhase >= 3 && (
                <div className="action-buttons">
                  <button className="primary-action">
                    <Heart className="w-5 h-5" />
                    Save Decision
                  </button>
                  <button className="secondary-action">
                    <Share className="w-5 h-5" />
                    Share
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Bottom Actions */}
          <div className="p-5 pb-8">
            <button
              onClick={() => {
                setShowResult(false);
                setPrice('');
                setAnimationPhase(0);
              }}
              className="w-full h-12 bg-white bg-opacity-20 backdrop-blur-lg text-white rounded-xl font-semibold border border-white border-opacity-30 transition-all duration-200 active:scale-95"
            >
              Calculate Another Item
            </button>
          </div>
        </>
      )}

      <style jsx>{`
        .header {
          height: 72px;
          background: linear-gradient(135deg, #8B5CF6 0%, #A855F7 100%);
          padding: 0 20px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 100;
        }

        .title {
          color: white;
          font-size: 18px;
          font-weight: 600;
          text-align: center;
          flex: 1;
        }

        .input-section {
          padding: 24px 20px;
          background: linear-gradient(180deg, rgba(139, 92, 246, 0.8) 0%, transparent 100%);
        }

        .price-input-wrapper {
          position: relative;
          margin-bottom: 16px;
        }

        .price-input {
          width: 100%;
          height: 56px;
          font-size: 24px;
          font-weight: 600;
          text-align: center;
          background: rgba(255, 255, 255, 0.95);
          border: 2px solid transparent;
          border-radius: 16px;
          box-shadow: 0 8px 32px rgba(139, 92, 246, 0.15);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          outline: none;
        }

        .price-input:focus {
          border-color: #EC4899;
          transform: translateY(-2px);
          box-shadow: 0 12px 40px rgba(139, 92, 246, 0.25);
        }

        .camera-scan-btn {
          position: absolute;
          right: 8px;
          top: 8px;
          width: 40px;
          height: 40px;
          background: linear-gradient(135deg, #EC4899 0%, #F472B6 100%);
          border: none;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          box-shadow: 0 4px 16px rgba(236, 72, 153, 0.4);
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .camera-scan-btn:active {
          transform: scale(0.95);
        }

        .presets-row {
          display: flex;
          gap: 8px;
          overflow-x: auto;
          padding: 0 0 8px 0;
        }

        .preset-btn {
          min-width: 80px;
          height: 32px;
          padding: 0 16px;
          background: rgba(255, 255, 255, 0.2);
          border: 1px solid rgba(255, 255, 255, 0.3);
          border-radius: 16px;
          color: white;
          font-size: 14px;
          font-weight: 500;
          white-space: nowrap;
          backdrop-filter: blur(10px);
          transition: all 0.2s ease;
          cursor: pointer;
        }

        .preset-btn:active {
          transform: scale(0.95);
          background: rgba(255, 255, 255, 0.3);
        }

        .impact-visualization {
          padding: 24px 20px;
          background: #FAFAFB;
        }

        .journey-header {
          text-align: center;
          margin-bottom: 24px;
        }

        .journey-title {
          font-size: 20px;
          font-weight: 600;
          color: #1F2937;
          margin-bottom: 8px;
        }

        .journey-subtitle {
          font-size: 14px;
          color: #6B7280;
        }

        .before-after-container {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          margin-bottom: 24px;
        }

        .progress-card {
          background: rgba(255, 255, 255, 0.95);
          border-radius: 20px;
          padding: 20px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
          position: relative;
          overflow: hidden;
          text-align: center;
        }

        .progress-card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          height: 4px;
          background: linear-gradient(135deg, #8B5CF6 0%, #A855F7 100%);
        }

        .card-label {
          font-size: 12px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          color: #6B7280;
          margin-bottom: 8px;
        }

        .progress-ring {
          width: 60px;
          height: 60px;
          margin: 0 auto 12px;
          position: relative;
        }

        .goal-title {
          font-size: 14px;
          font-weight: 600;
          color: #1F2937;
          margin-bottom: 4px;
        }

        .goal-progress {
          font-size: 12px;
          color: #6B7280;
        }

        .goal-impact-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .goal-impact-item {
          display: flex;
          align-items: center;
          padding: 16px;
          background: rgba(255, 255, 255, 0.95);
          border-radius: 16px;
          border-left: 4px solid #10B981;
          animation: slideInRight 0.3s ease-out;
        }

        .goal-impact-item.delayed {
          border-left-color: #F59E0B;
        }

        .goal-impact-item.accelerated {
          border-left-color: #10B981;
        }

        .impact-icon {
          width: 32px;
          height: 32px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 12px;
          font-size: 16px;
        }

        .impact-content {
          flex: 1;
        }

        .impact-title {
          font-size: 14px;
          font-weight: 600;
          color: #1F2937;
          margin-bottom: 2px;
        }

        .impact-description {
          font-size: 12px;
          color: #6B7280;
        }

        .impact-change {
          font-size: 12px;
          font-weight: 600;
          text-align: right;
        }

        .impact-change.positive { color: #10B981; }
        .impact-change.negative { color: #F59E0B; }

        .decision-result {
          padding: 24px 20px;
          text-align: center;
          background: #FAFAFB;
        }

        .recommendation-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 12px 24px;
          border-radius: 20px;
          font-size: 16px;
          font-weight: 600;
          margin-bottom: 16px;
          animation: bounceIn 0.5s ease-out;
        }

        .badge-go-for-it {
          background: linear-gradient(135deg, #10B981 0%, #34D399 100%);
          color: white;
          box-shadow: 0 8px 32px rgba(16, 185, 129, 0.3);
        }

        .badge-maybe-wait {
          background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%);
          color: white;
          box-shadow: 0 8px 32px rgba(245, 158, 11, 0.3);
        }

        .badge-save-more {
          background: linear-gradient(135deg, #06B6D4 0%, #38BDF8 100%);
          color: white;
          box-shadow: 0 8px 32px rgba(6, 182, 212, 0.3);
        }

        .supporting-message {
          font-size: 16px;
          line-height: 24px;
          color: #1F2937;
          margin-bottom: 24px;
          max-width: 300px;
          margin-left: auto;
          margin-right: auto;
        }

        .action-buttons {
          display: flex;
          gap: 12px;
          margin-top: 20px;
        }

        .primary-action {
          flex: 1;
          height: 48px;
          background: linear-gradient(135deg, #8B5CF6 0%, #A855F7 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          box-shadow: 0 4px 16px rgba(139, 92, 246, 0.3);
          transition: all 0.2s ease;
          cursor: pointer;
        }

        .primary-action:active {
          transform: translateY(1px);
          box-shadow: 0 2px 8px rgba(139, 92, 246, 0.4);
        }

        .secondary-action {
          flex: 1;
          height: 48px;
          background: rgba(255, 255, 255, 0.95);
          color: #1F2937;
          border: 1px solid #E5E7EB;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          transition: all 0.2s ease;
          cursor: pointer;
        }

        @keyframes slideInRight {
          from {
            opacity: 0;
            transform: translateX(20px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }

        @keyframes bounceIn {
          0% {
            opacity: 0;
            transform: scale(0.8);
          }
          50% {
            transform: scale(1.05);
          }
          100% {
            opacity: 1;
            transform: scale(1);
          }
        }
      `}</style>
    </div>
  );
};

export default ShouldIBuyCalculator;