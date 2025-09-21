# PiggyBong2 Agent Coordination Workflow

## 🎯 Agent Team Overview

### Active Agents Connected
1. **studio-coach** - Strategic coordination and motivation
2. **rapid-prototyper** - MVP development and feature implementation  
3. **trend-researcher** - Market analysis and viral opportunity identification
4. **project-shipper** - Deployment strategy and launch execution
5. **tiktok-strategist** - Viral marketing and content strategy (ready to activate)
6. **app-store-optimizer** - ASO and conversion optimization (ready to activate)
7. **experiment-tracker** - A/B testing and analytics (ready to activate)

## 🔄 Daily Agent Workflow

### Morning Sprint (9:00 AM)
```bash
# Studio Coach leads daily standup
- Review overnight metrics and user feedback
- Assign priority tasks to specialized agents
- Set daily success metrics
```

### Midday Execution (12:00 PM)
```bash
# Parallel agent execution
- rapid-prototyper: Feature implementation
- trend-researcher: Real-time trend monitoring
- project-shipper: Deployment preparation
- tiktok-strategist: Content creation
```

### Evening Sync (5:00 PM)
```bash
# Progress review and handoffs
- Commit all code changes (auto-commit.sh)
- Update project status
- Plan next day priorities
```

## 📊 Agent Communication Protocol

### Information Flow
```
trend-researcher → rapid-prototyper
    ↓                    ↓
tiktok-strategist → project-shipper
    ↓                    ↓
app-store-optimizer → studio-coach
```

### Trigger Events
- **New Trend Detected** → trend-researcher alerts all agents
- **Feature Complete** → rapid-prototyper triggers project-shipper
- **Viral Moment** → tiktok-strategist activates all agents
- **User Feedback Spike** → experiment-tracker initiates rapid response

## 🚀 Launch Week Agent Responsibilities

### Day 1-2: Foundation
- **rapid-prototyper**: Final bug fixes and polish
- **project-shipper**: App Store submission
- **tiktok-strategist**: Pre-launch buzz creation

### Day 3-4: Beta Testing
- **experiment-tracker**: Monitor beta metrics
- **rapid-prototyper**: Quick iteration on feedback
- **trend-researcher**: Community sentiment analysis

### Day 5-6: Launch
- **project-shipper**: Execute launch runbook
- **tiktok-strategist**: Release viral content
- **studio-coach**: Coordinate real-time response

## 💡 Agent Activation Commands

### Quick Agent Deployment
```bash
# Activate specific agent for task
claude-code agent:[agent-name] "[specific task]"

# Examples:
claude-code agent:rapid-prototyper "Add social sharing feature"
claude-code agent:trend-researcher "Analyze BLACKPINK comeback impact"
claude-code agent:tiktok-strategist "Create viral challenge concept"
```

### Batch Agent Operations
```bash
# Morning activation sequence
./agents/morning-sprint.sh

# Launch preparation
./agents/launch-prep.sh

# Emergency response
./agents/crisis-response.sh
```

## 📈 Success Metrics by Agent

### rapid-prototyper
- Features shipped per sprint: 5+
- Code quality score: 90%+
- User-reported bugs: <5 per release

### trend-researcher  
- Trend identification accuracy: 80%+
- Actionable insights per week: 10+
- Viral opportunity capture rate: 60%+

### project-shipper
- Launch on schedule: 100%
- App Store approval: First submission
- Post-launch stability: 99.9% uptime

### tiktok-strategist
- Viral content pieces: 3+ per week
- Engagement rate: 10%+
- Follower growth: 1000+ per day during launch

## 🔧 Agent Maintenance

### Daily Tasks
- Sync with GitHub repository
- Update Supabase configurations
- Monitor agent performance metrics

### Weekly Tasks
- Agent performance review
- Workflow optimization
- Knowledge base updates

### Sprint Tasks
- Agent capability expansion
- Integration improvements
- Success metric recalibration

## 🎯 Current Sprint Focus

### Immediate Priorities (Next 48 Hours)
1. **Complete App Store submission materials** (project-shipper)
2. **Fix remaining UI bugs** (rapid-prototyper)
3. **Create launch week content** (tiktok-strategist)
4. **Set up analytics tracking** (experiment-tracker)

### This Week Goals
- Beta testing program launch
- 50+ beta testers recruited
- App Store submission complete
- 20+ TikTok videos created
- Analytics dashboard operational

## 📞 Emergency Protocols

### Critical Issue Response
1. **studio-coach** assesses severity
2. **rapid-prototyper** implements hot fix
3. **project-shipper** manages deployment
4. **tiktok-strategist** handles communication

### Viral Growth Response
1. **project-shipper** scales infrastructure
2. **rapid-prototyper** optimizes performance
3. **experiment-tracker** monitors metrics
4. **studio-coach** coordinates response

## 🔗 Integration Points

### GitHub Repository
- Auto-commit enabled: `./auto-commit.sh`
- Branch strategy: main → develop → feature branches
- PR reviews by studio-coach agent

### Supabase Backend
- URL: `https://YOUR-PROJECT.supabase.co`
- Real-time subscriptions for agent coordination
- Analytics events for agent decisions

### External Services
- RevenueCat: Subscription management
- TikTok API: Content performance tracking
- App Store Connect: Release management

## ✅ Agent Coordination Checklist

### Daily
- [ ] Morning agent sync
- [ ] Task assignment and prioritization
- [ ] Progress tracking
- [ ] Evening commit and review
- [ ] Next day planning

### Weekly
- [ ] Sprint planning with all agents
- [ ] Performance metrics review
- [ ] User feedback integration
- [ ] Market trend analysis
- [ ] Content calendar update

### Monthly
- [ ] Agent capability assessment
- [ ] Workflow optimization
- [ ] Strategic pivot evaluation
- [ ] Competitive analysis update
- [ ] Growth strategy refinement

---

## 🚦 Current Status: READY FOR LAUNCH

All agents are connected, coordinated, and ready to execute the PiggyBong2 launch strategy. The rapid-prototyper has delivered a functional MVP, trend-researcher has identified market opportunities, and project-shipper has created the deployment roadmap.

**Next Action**: Execute `./auto-commit.sh` to save all agent work, then begin beta testing recruitment.

---

*Last Updated: 2025-08-29*
*Agent Coordination Version: 1.0*