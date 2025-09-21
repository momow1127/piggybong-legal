# TestFlight Setup Guide for PiggyBong
## Quick Setup (30 minutes)

### ✅ Prerequisites
- [ ] Apple Developer Account ($99/year)
- [ ] App Store Connect access
- [ ] Xcode 14+ installed

### 📱 Step 1: Prepare Your Build (5 mins)
1. Open `FanPlan.xcodeproj` in Xcode
2. Select "Piggy Bong" target
3. Go to Signing & Capabilities
4. Ensure Team is set to your Apple Developer account
5. Bump version number: `1.0.0` → `1.0.1`

### 🎯 Step 2: Archive & Upload (10 mins)
```bash
# In Xcode:
1. Product → Scheme → "Piggy Bong"
2. Product → Destination → "Any iOS Device"
3. Product → Archive
4. Once complete: Window → Organizer
5. Click "Distribute App"
6. Choose "App Store Connect"
7. Upload
```

### 👥 Step 3: Add Beta Testers (5 mins)
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select PiggyBong
3. Go to TestFlight tab
4. Add Internal Testers (yourself + 1-2 friends)
   - No review needed
   - Instant access
5. Add External Testers (up to 10,000)
   - Needs brief review (24 hours)
   - Create a public link

### 📧 Step 4: Invite Testers (5 mins)
```
Email Template:
Subject: 🐷 Help Test PiggyBong Before Launch!

Hi [Name],

You're invited to beta test PiggyBong - the K-pop fan budgeting app!

1. Download TestFlight: https://apps.apple.com/app/testflight/id899247664
2. Click this link: [Your TestFlight Link]
3. Install PiggyBong
4. Test & send feedback!

What to test:
- Sign up flow
- Add your favorite artists
- Set savings goals
- Report any bugs

Thanks!
[Your name]
```

### 🎉 Step 5: Quick Win Strategy
**Even with 0 testers, TestFlight helps because:**
- Forces you to do a real build
- Tests the upload process
- Catches signing issues early
- You can test on your own devices
- Shows App Store Connect works

### ⚡ Super Fast Alternative (If no time):
Just invite yourself + 1 family member as internal testers. This takes 10 minutes total and still gives you:
- Real device testing
- Crash reports
- Installation practice

### 📊 What to Track:
- Crashes (automatic in TestFlight)
- Installation success rate
- Feedback (built into TestFlight)

### 🚨 Common Issues:
1. **"Missing compliance"** → Export Compliance: Select "No encryption"
2. **"Invalid binary"** → Check version number is unique
3. **"Missing icon"** → Ensure all App Icon sizes are filled

### 💡 Pro Tips:
1. Upload Friday, test weekend
2. Fix critical bugs only
3. Ship to App Store by Sept 28
4. You can update TestFlight build daily
5. TestFlight builds expire after 90 days

---

## Minimal TestFlight (If absolutely no time):
1. Archive & Upload to App Store Connect
2. Don't add any testers
3. Just having it there = backup plan
4. Can activate testers anytime before launch

Remember: **Perfect is the enemy of shipped!** 🚀