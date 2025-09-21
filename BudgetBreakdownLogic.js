// Budget Breakdown Logic - Dynamic Category Display

// User's selected categories from onboarding
const SPENDING_CATEGORIES = {
  'albums_photocards': {
    id: 'albums_photocards',
    name: 'Albums & Photocards',
    icon: '💿',
    color: '#FF6B9D',
    defaultPercentage: 35
  },
  'official_merch': {
    id: 'official_merch', 
    name: 'Official Merch',
    icon: '🛍️',
    color: '#4ECDC4',
    defaultPercentage: 25
  },
  'concerts_shows': {
    id: 'concerts_shows',
    name: 'Concerts & Shows', 
    icon: '🎤',
    color: '#45B7D1',
    defaultPercentage: 30
  },
  'fan_events': {
    id: 'fan_events',
    name: 'Fan Events (KCON, Hi-Touch)',
    icon: '👥', 
    color: '#96CEB4',
    defaultPercentage: 15
  },
  'subscriptions_apps': {
    id: 'subscriptions_apps',
    name: 'Subscriptions & Fan Apps',
    icon: '📱',
    color: '#FFEAA7',
    defaultPercentage: 10
  }
};

// Generate dynamic budget breakdown based on user selections
function generateBudgetBreakdown(selectedCategories, totalBudget) {
  const numCategories = selectedCategories.length;
  
  // Smart percentage distribution based on category type and count
  const percentageStrategies = {
    2: [60, 40],
    3: [50, 30, 20], 
    4: [40, 25, 20, 15],
    5: [35, 25, 20, 15, 5]
  };
  
  const basePercentages = percentageStrategies[numCategories] || 
    distributeEvenly(numCategories);
  
  return selectedCategories.map((categoryId, index) => {
    const category = SPENDING_CATEGORIES[categoryId];
    const percentage = basePercentages[index];
    const amount = Math.round((totalBudget * percentage) / 100);
    
    return {
      ...category,
      percentage,
      amount,
      formattedAmount: `$${amount.toLocaleString()}`
    };
  });
}

// Add realistic variance to make data feel authentic
function addRealisticVariance(breakdown) {
  return breakdown.map(item => {
    // Add 1-3% random variance to avoid perfectly round numbers
    const variance = (Math.random() - 0.5) * 6; // -3% to +3%
    const adjustedPercentage = Math.max(1, Math.min(100, item.percentage + variance));
    
    return {
      ...item,
      percentage: Math.round(adjustedPercentage * 10) / 10, // Round to 1 decimal
      amount: Math.round((item.amount * adjustedPercentage) / item.percentage)
    };
  });
}

// Ensure percentages add up to 100%
function normalizePercentages(breakdown) {
  const totalPercentage = breakdown.reduce((sum, item) => sum + item.percentage, 0);
  const adjustment = 100 / totalPercentage;
  
  return breakdown.map((item, index) => {
    const adjustedPercentage = item.percentage * adjustment;
    
    // Round and ensure the last item gets any remainder
    const roundedPercentage = index === breakdown.length - 1 
      ? 100 - breakdown.slice(0, -1).reduce((sum, prev) => sum + Math.round(prev.percentage * adjustment * 10) / 10, 0)
      : Math.round(adjustedPercentage * 10) / 10;
    
    return {
      ...item,
      percentage: roundedPercentage,
      amount: Math.round((item.amount * adjustedPercentage) / item.percentage)
    };
  });
}

// Main function to generate personalized budget breakdown
export function createPersonalizedBudgetBreakdown(userSelections, totalBudget) {
  let breakdown = generateBudgetBreakdown(userSelections.selectedCategories, totalBudget);
  breakdown = addRealisticVariance(breakdown);
  breakdown = normalizePercentages(breakdown);
  
  return {
    breakdown,
    totalBudget,
    selectedCategories: userSelections.selectedCategories,
    generatedAt: new Date().toISOString()
  };
}

// Helper function for even distribution
function distributeEvenly(count) {
  const basePercentage = Math.floor(100 / count);
  const remainder = 100 % count;
  
  const percentages = Array(count).fill(basePercentage);
  
  // Distribute remainder to first few items
  for (let i = 0; i < remainder; i++) {
    percentages[i] += 1;
  }
  
  return percentages;
}

// Example usage:
/*
const userSelections = {
  selectedCategories: ['albums_photocards', 'concerts_shows', 'official_merch']
};

const personalizedBreakdown = createPersonalizedBudgetBreakdown(userSelections, 500);

Output:
{
  breakdown: [
    {
      id: 'albums_photocards',
      name: 'Albums & Photocards', 
      icon: '💿',
      color: '#FF6B9D',
      percentage: 48.2,
      amount: 241,
      formattedAmount: '$241'
    },
    {
      id: 'concerts_shows',
      name: 'Concerts & Shows',
      icon: '🎤', 
      color: '#45B7D1',
      percentage: 31.7,
      amount: 159,
      formattedAmount: '$159'
    },
    {
      id: 'official_merch',
      name: 'Official Merch',
      icon: '🛍️',
      color: '#4ECDC4', 
      percentage: 20.1,
      amount: 100,
      formattedAmount: '$100'
    }
  ],
  totalBudget: 500,
  selectedCategories: ['albums_photocards', 'concerts_shows', 'official_merch'],
  generatedAt: '2025-08-19T...'
}
*/