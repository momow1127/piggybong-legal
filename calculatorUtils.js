// Calculator utility functions for "Should I Buy This?" feature

/**
 * Calculates the financial impact of a purchase on user goals
 * @param {number} purchaseAmount - The amount of the item to purchase
 * @param {Object} userProfile - User's financial profile and goals
 * @returns {Object} Impact analysis with recommendations
 */
export const calculatePurchaseImpact = (purchaseAmount, userProfile) => {
  const { monthlyBudget, goals, currentSavings } = userProfile;
  
  // Calculate budget impact percentage
  const budgetImpact = (purchaseAmount / monthlyBudget) * 100;
  
  // Calculate goal delays
  const goalImpacts = goals.map(goal => {
    const remainingAmount = goal.target - goal.current;
    const monthsToGoal = remainingAmount / (monthlyBudget * 0.3); // 30% savings rate
    const delayDays = Math.ceil((purchaseAmount / (monthlyBudget * 0.3)) * 30);
    
    return {
      ...goal,
      originalDays: Math.ceil(monthsToGoal * 30),
      delayDays,
      newDays: Math.ceil(monthsToGoal * 30) + delayDays,
      severity: delayDays > 30 ? 'high' : delayDays > 14 ? 'medium' : 'low'
    };
  });
  
  // Determine overall recommendation
  let recommendation;
  if (budgetImpact <= 20) {
    recommendation = {
      type: 'go-for-it',
      confidence: 'high',
      badge: "✨ Go For It!",
      message: "You've got this! This fits perfectly in your stan budget 💜",
      color: 'green'
    };
  } else if (budgetImpact <= 40) {
    recommendation = {
      type: 'maybe-wait',
      confidence: 'medium',
      badge: "🤔 Maybe Wait?",
      message: "Almost there! Maybe save for one more week? You're doing amazing! 💪",
      color: 'amber'
    };
  } else {
    recommendation = {
      type: 'save-more',
      confidence: 'high',
      badge: "💙 Trust The Process",
      message: "Your future self will thank you for this patience. You're building something beautiful! 🌟",
      color: 'blue'
    };
  }
  
  return {
    budgetImpact,
    goalImpacts,
    recommendation,
    purchaseAmount,
    canAfford: currentSavings >= purchaseAmount
  };
};

/**
 * Generates supportive messages based on purchase impact
 * @param {Object} impact - Impact analysis from calculatePurchaseImpact
 * @returns {Object} Personalized messages for the user
 */
export const generateSupportiveMessages = (impact) => {
  const { recommendation, goalImpacts } = impact;
  
  const messageVariations = {
    'go-for-it': [
      "You've got this! This fits perfectly in your stan budget 💜",
      "Your goals are still on track - treat yourself!",
      "This purchase supports your journey beautifully ✨",
      "Amazing discipline! You've earned this reward 🌟"
    ],
    
    'maybe-wait': [
      "Almost there! Maybe save for one more week? 💪",
      "Your commitment is inspiring - so close to your goal!",
      "What if we wait just a tiny bit longer? You're doing amazing!",
      "Think of the satisfaction when you can afford this AND reach your goals!"
    ],
    
    'save-more': [
      "Your future self will thank you for this patience 🌟",
      "Think of how good it'll feel when you can afford this AND your goals!",
      "You're building something beautiful - keep going!",
      "This discipline is what separates dreamers from achievers! 💪"
    ]
  };
  
  // Select a random supportive message
  const messages = messageVariations[recommendation.type];
  const randomMessage = messages[Math.floor(Math.random() * messages.length)];
  
  // Generate goal-specific encouragement
  const goalEncouragement = goalImpacts.map(goal => {
    if (goal.delayDays <= 7) {
      return `Your ${goal.title} is barely affected - you're crushing it! 🎯`;
    } else if (goal.delayDays <= 30) {
      return `${goal.title} gets delayed by ${goal.delayDays} days, but you're still on an amazing path! 💜`;
    } else {
      return `${goal.title} needs more time, but imagine how sweet the victory will be! ⭐`;
    }
  });
  
  return {
    primary: randomMessage,
    goalSpecific: goalEncouragement,
    celebration: generateCelebrationMessage(recommendation.type)
  };
};

/**
 * Generates celebration messages for positive financial decisions
 * @param {string} recommendationType - Type of recommendation
 * @returns {string} Celebration message
 */
const generateCelebrationMessage = (recommendationType) => {
  const celebrations = {
    'go-for-it': "Achievement Unlocked: Smart Spender! 🏆",
    'maybe-wait': "Patience Level: Stan Dedication! 💜",
    'save-more': "Future Self Mode: Activated! ⭐"
  };
  
  return celebrations[recommendationType];
};

/**
 * Calculates savings progress for visual progress rings
 * @param {number} current - Current saved amount
 * @param {number} target - Target amount
 * @returns {Object} Progress data for UI components
 */
export const calculateProgress = (current, target) => {
  const percentage = Math.min((current / target) * 100, 100);
  const remaining = Math.max(target - current, 0);
  const isComplete = current >= target;
  
  return {
    percentage: Math.round(percentage),
    remaining,
    isComplete,
    displayText: `$${current} / $${target}`,
    progressColor: percentage >= 80 ? 'green' : percentage >= 50 ? 'blue' : 'purple'
  };
};

/**
 * Formats currency for display in the UI
 * @param {number} amount - Amount to format
 * @param {boolean} showCents - Whether to show cents
 * @returns {string} Formatted currency string
 */
export const formatCurrency = (amount, showCents = false) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: showCents ? 2 : 0,
    maximumFractionDigits: showCents ? 2 : 0
  }).format(amount);
};

/**
 * Generates quick preset amounts based on user spending patterns
 * @param {Object} userProfile - User's financial profile
 * @returns {Array} Array of preset amounts
 */
export const generateQuickPresets = (userProfile) => {
  const { monthlyBudget, recentPurchases } = userProfile;
  
  // Base presets
  const basePresets = [5, 10, 25, 50, 100];
  
  // Add common purchase amounts from history
  const commonAmounts = recentPurchases
    .reduce((acc, purchase) => {
      const rounded = Math.round(purchase.amount / 5) * 5; // Round to nearest $5
      acc[rounded] = (acc[rounded] || 0) + 1;
      return acc;
    }, {});
    
  // Get top 3 most common amounts
  const popularAmounts = Object.entries(commonAmounts)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 3)
    .map(([amount]) => parseInt(amount))
    .filter(amount => amount >= 5 && amount <= monthlyBudget * 0.5);
    
  // Combine and deduplicate
  const allPresets = [...new Set([...basePresets, ...popularAmounts])];
  
  // Sort and return top 5
  return allPresets
    .sort((a, b) => a - b)
    .slice(0, 5)
    .map(amount => `$${amount}`);
};

/**
 * Calculates delay impact in user-friendly terms
 * @param {number} delayDays - Number of days delayed
 * @returns {string} Human-readable delay description
 */
export const formatDelayImpact = (delayDays) => {
  if (delayDays <= 0) return "No delay";
  if (delayDays <= 7) return `${delayDays} day${delayDays === 1 ? '' : 's'}`;
  if (delayDays <= 30) return `${Math.ceil(delayDays / 7)} week${Math.ceil(delayDays / 7) === 1 ? '' : 's'}`;
  return `${Math.ceil(delayDays / 30)} month${Math.ceil(delayDays / 30) === 1 ? '' : 's'}`;
};

/**
 * Determines if purchase timing is optimal based on pay cycles and bills
 * @param {Object} userProfile - User's financial profile
 * @param {Date} purchaseDate - Planned purchase date
 * @returns {Object} Timing analysis
 */
export const analyzePurchaseTiming = (userProfile, purchaseDate = new Date()) => {
  const { payDates, billDates, monthlyBudget } = userProfile;
  
  const dayOfMonth = purchaseDate.getDate();
  const nextPayDay = payDates.find(day => day > dayOfMonth) || payDates[0] + 30;
  const daysUntilPay = nextPayDay > dayOfMonth ? nextPayDay - dayOfMonth : (30 - dayOfMonth) + nextPayDay;
  
  const upcomingBills = billDates.filter(day => day > dayOfMonth && day <= dayOfMonth + 7);
  
  let timing = 'good';
  let message = "Great timing for this purchase! 💜";
  
  if (upcomingBills.length > 0) {
    timing = 'caution';
    message = "Bills coming up soon - maybe wait a few days? 📅";
  } else if (daysUntilPay <= 3) {
    timing = 'excellent';
    message = "Perfect timing! Payday vibes! 💸";
  }
  
  return {
    timing,
    message,
    daysUntilPay,
    upcomingBills: upcomingBills.length
  };
};

export default {
  calculatePurchaseImpact,
  generateSupportiveMessages,
  calculateProgress,
  formatCurrency,
  generateQuickPresets,
  formatDelayImpact,
  analyzePurchaseTiming
};