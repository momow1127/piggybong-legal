// BudgetBreakdownScreen.tsx - Dynamic Budget Breakdown Component

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  Dimensions,
  TouchableOpacity,
  Animated
} from 'react-native';
import { createPersonalizedBudgetBreakdown } from './BudgetBreakdownLogic';

interface BudgetBreakdownProps {
  userSelections: {
    selectedCategories: string[];
    totalBudget: number;
  };
  onContinue: () => void;
}

const { width: screenWidth } = Dimensions.get('window');

export const BudgetBreakdownScreen: React.FC<BudgetBreakdownProps> = ({
  userSelections,
  onContinue
}) => {
  const [budgetData, setBudgetData] = useState(null);
  const [animatedValues, setAnimatedValues] = useState([]);

  useEffect(() => {
    // Generate personalized budget breakdown
    const personalizedData = createPersonalizedBudgetBreakdown(
      userSelections,
      userSelections.totalBudget
    );
    setBudgetData(personalizedData);

    // Initialize animations for each category
    const animations = personalizedData.breakdown.map(() => new Animated.Value(0));
    setAnimatedValues(animations);

    // Animate bars with staggered timing
    animations.forEach((animValue, index) => {
      Animated.timing(animValue, {
        toValue: 1,
        duration: 800,
        delay: index * 150,
        useNativeDriver: false,
      }).start();
    });
  }, [userSelections]);

  if (!budgetData) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Personalizing your budget...</Text>
      </View>
    );
  }

  const renderBudgetItem = (item, index) => {
    const animatedValue = animatedValues[index];
    const barWidth = animatedValue.interpolate({
      inputRange: [0, 1],
      outputRange: [0, (item.percentage / 100) * (screenWidth - 80)],
    });

    return (
      <View key={item.id} style={styles.budgetItem}>
        <View style={styles.categoryHeader}>
          <View style={styles.categoryInfo}>
            <Text style={styles.categoryIcon}>{item.icon}</Text>
            <View style={styles.categoryText}>
              <Text style={styles.categoryName}>{item.name}</Text>
              <Text style={styles.categoryAmount}>{item.formattedAmount}</Text>
            </View>
          </View>
          <Text style={styles.percentage}>{item.percentage}%</Text>
        </View>
        
        <View style={styles.progressBarContainer}>
          <Animated.View
            style={[
              styles.progressBar,
              {
                backgroundColor: item.color,
                width: barWidth,
              },
            ]}
          />
        </View>
      </View>
    );
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      <View style={styles.header}>
        <Text style={styles.title}>Your Personalized Budget</Text>
        <Text style={styles.subtitle}>
          Based on your selected spending categories
        </Text>
        <Text style={styles.totalBudget}>
          ${budgetData.totalBudget.toLocaleString()} / month
        </Text>
      </View>

      <View style={styles.breakdownContainer}>
        <Text style={styles.sectionTitle}>Budget Breakdown</Text>
        <Text style={styles.sectionSubtitle}>
          Optimized for your {budgetData.breakdown.length} selected categories
        </Text>
        
        {budgetData.breakdown.map((item, index) => renderBudgetItem(item, index))}
      </View>

      <View style={styles.insightContainer}>
        <Text style={styles.insightTitle}>💡 Smart Insights</Text>
        <View style={styles.insightItem}>
          <Text style={styles.insightText}>
            Your largest allocation is for {budgetData.breakdown[0].name} 
            ({budgetData.breakdown[0].percentage}%)
          </Text>
        </View>
        <View style={styles.insightItem}>
          <Text style={styles.insightText}>
            This breakdown can be adjusted anytime in your settings
          </Text>
        </View>
      </View>

      <TouchableOpacity style={styles.continueButton} onPress={onContinue}>
        <Text style={styles.continueButtonText}>Looks Good!</Text>
      </TouchableOpacity>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Don't worry, you can adjust these percentages later
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  loadingText: {
    fontSize: 16,
    color: '#666666',
    fontWeight: '500',
  },
  header: {
    paddingHorizontal: 24,
    paddingTop: 40,
    paddingBottom: 32,
    alignItems: 'center',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1A1A1A',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666666',
    textAlign: 'center',
    marginBottom: 16,
  },
  totalBudget: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#FF6B9D',
    textAlign: 'center',
  },
  breakdownContainer: {
    paddingHorizontal: 24,
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1A1A1A',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 14,
    color: '#666666',
    marginBottom: 24,
  },
  budgetItem: {
    marginBottom: 24,
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  categoryInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  categoryIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  categoryText: {
    flex: 1,
  },
  categoryName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1A1A1A',
    marginBottom: 2,
  },
  categoryAmount: {
    fontSize: 14,
    color: '#666666',
    fontWeight: '500',
  },
  percentage: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1A1A1A',
  },
  progressBarContainer: {
    height: 8,
    backgroundColor: '#F0F0F0',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    borderRadius: 4,
  },
  insightContainer: {
    marginHorizontal: 24,
    padding: 20,
    backgroundColor: '#F8F9FA',
    borderRadius: 12,
    marginBottom: 32,
  },
  insightTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1A1A1A',
    marginBottom: 12,
  },
  insightItem: {
    marginBottom: 8,
  },
  insightText: {
    fontSize: 14,
    color: '#666666',
    lineHeight: 20,
  },
  continueButton: {
    marginHorizontal: 24,
    backgroundColor: '#FF6B9D',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 16,
  },
  continueButtonText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  footer: {
    paddingHorizontal: 24,
    paddingBottom: 40,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: '#999999',
    textAlign: 'center',
  },
});