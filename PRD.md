MVP PRD

Product
Taiwan Badminton Match (台灣羽球零打媒合平台)

Goal
Create a centralized mobile app where hosts can publish badminton sessions and players can quickly discover, evaluate, and join suitable games without relying on fragmented Facebook groups or LINE chats.

1. Target Audience & Core Value Proposition

Target Audience

Players (球友): People in Taiwan looking for nearby badminton sessions that match their location, time, fee, and skill level.
Hosts (主揪): People who organize badminton sessions and need a faster way to fill slots with suitable players.
Guests: New users browsing available games before registration.
Core Value Proposition

For players: Find the right game faster with transparent filters for city/district, time, level, fee, and vacancy.
For hosts: Fill courts more efficiently with clearer player expectations and less manual coordination.
For both: Reduce mismatch and disputes through standardized game details and a shared skill-level framework.
Success Criteria for MVP

Users can discover games by area and time in under 1 minute.
Hosts can publish a game in under 3 minutes.
Players can request/join a game in under 1 minute.
Core matching disputes are reduced by showing clear skill level, fee, location, and remaining slots.
2. User Stories

Guest

As a guest, I want to browse game listings, so that I can see whether the app has useful games before registering.
As a guest, I want to filter games by city/district, so that I can quickly check sessions near me.
As a guest, I want to view basic game details, so that I can decide whether to sign up.
Player

As a player, I want to sign up and create a profile, so that hosts can understand who I am.
As a player, I want to set my badminton skill level, so that I can join games that match my ability.
As a player, I want to search and filter games by city, district, date/time, level, and fee, so that I can find suitable sessions quickly.
As a player, I want to view full game details, so that I know the venue, host, cost, level, and available spots before joining.
As a player, I want to join or request to join a game, so that I can secure a spot without messaging multiple groups.
As a player, I want to see my upcoming joined games, so that I can manage my schedule.
Host

As a host, I want to sign up and create a host profile, so that players can trust the session organizer.
As a host, I want to create a game with structured fields, so that players can understand the session without back-and-forth questions.
As a host, I want to define skill level requirements, so that I can reduce level mismatch.
As a host, I want to set player capacity and track remaining spots, so that I can manage attendance.
As a host, I want to review join requests or participants, so that I can control who joins my game.
As a host, I want to see my created games in one place, so that I can manage upcoming sessions efficiently.
3. Core Features List for MVP

P0: Must Build First

Authentication
Phone number or email sign-up/login
Basic profile creation
User Profile
Nickname
Avatar
Gender optional
Skill level
Preferred play area
Game Listing Feed
Browse upcoming games
Show key summary: date, time, city/district, venue, fee, level, remaining spots
Search & Filters
Taiwan city
District
Date/time
Skill level
Fee range
Vacancy only
Game Detail Page
Full venue info
Host name
Skill requirement
number of courts
session duration
shuttle type optional
fee
joined count / remaining slots
notes/rules
Create a Game
Host creates session with structured form
Join a Game
One-tap join or request-to-join flow
Capacity control
My Games
Joined games for players
Created games for hosts
P1: Important but Can Follow After Launch

Push notifications for join confirmation / updates
Host approval mode: auto-accept vs manual approval
In-app chat or contact handoff
Cancel leave flow
Reporting / blocking
Saved filters or favorite venues
Out of Scope for MVP

Payments / escrow
Ratings and reviews
Advanced recommendation engine
Tournament system
Membership / subscription features
4. Skill Level Definition

Goal: create a simple, localized standard that most Taiwan badminton users can self-select and understand.

Recommended 5-Level System

L1 新手
Very limited match experience
Basic grip/rules understood
Rally consistency is low
Suitable for casual beginner games
L2 初階
Can sustain short rallies
Basic forehand/backhand and serve
Understands doubles rotation roughly
Suitable for recreational beginner-intermediate games
L3 中階
Stable rallies and basic shot placement
Understands doubles positioning and game rhythm
Can play competitive recreational matches
Suitable for most regular club games
L4 進階
Strong movement, consistency, and tactical awareness
Can apply smash/drop/drive with intent
Often plays in club ladders or local competitions
Suitable for stronger fixed-level sessions
L5 校隊/甲乙組
School team, ex-team, or tournament-level players
Fast pace, structured tactics, strong footwork and control
Suitable for high-level competitive sessions only
Usage Rules in Product

Hosts must select a minimum recommended level and optionally a target range.
Players choose one self-assessed level during onboarding and can edit later.
Every game listing shows level clearly, for example: L2-L3 初階-中階.
Add helper text: “Level is for matching efficiency; hosts may still approve based on session needs.”
This balances clarity and simplicity better than overly granular rankings.

5. Information Architecture (IA)

Bottom Navigation
├─ Home
│  ├─ Game Feed
│  ├─ Search / Filter
│  └─ Game Detail
├─ Create
│  ├─ Create Game Form
│  └─ Create Success
├─ My Games
│  ├─ Joined Games
│  ├─ Created Games
│  └─ Game Management / Participant List
├─ Messages
│  ├─ System Notifications
│  └─ Host/Player Contact Thread (optional in MVP-lite)
└─ Profile
   ├─ View/Edit Profile
   ├─ Skill Level Setting
   ├─ Preferred Areas
   └─ Login / Account Settings
Recommended MVP Nav Simplification
If you want the leanest first release:

Bottom Navigation
├─ Home
├─ Create
├─ My Games
└─ Profile
Messages can be replaced initially by join status updates plus contact instructions on the game detail page.