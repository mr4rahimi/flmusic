🎵 Social Music Platform

A SoundCloud-like social music platform built with a modern full-stack architecture.
Users can upload music, follow creators, like tracks, comment, create playlists, and discover new music through social feeds.

🚀 Project Vision

This project aims to build a social-first music platform where:

Artists and users can upload music (UGC + Verified Artists)
Users can follow creators
Tracks can be liked, reposted, and commented on
Playlists can be created and shared
A social feed drives discovery
Mobile-first experience with a web companion

Think:

🎧 SoundCloud × 📱 Instagram Feed × 🎯 Creator Economy

🧱 Tech Stack
Web
Next.js (App Router)
TailwindCSS
TanStack Query
Zustand
Mobile App
Flutter
Riverpod
go_router
Backend
NestJS (TypeScript)
REST API + WebSockets
Database & Infra
PostgreSQL
Redis
Prisma ORM
Cloudflare R2 (File Storage)
Meilisearch (Search Engine)
FFmpeg (Audio Processing)
Realtime & Notifications
Socket.IO
Firebase Cloud Messaging (FCM)
🎯 Core Features (MVP)
🔐 Authentication
Email/Password login
OAuth (Google / Apple)
JWT + Refresh tokens
👤 User System
User profiles
Followers / Following
Verified artist badges
🎵 Music System
Upload tracks
Audio streaming
Cover image support
Track metadata (title, tags, genre)
❤️ Social Features
Like tracks
Comment on tracks
Repost/share tracks
Follow users
📻 Playlists
Create playlists
Add/remove tracks
Public/private playlists
📡 Feed System
Following feed
Trending feed
New uploads feed
🔍 Search
Search users, tracks, playlists
🔔 Notifications
Likes, follows, comments, reposts
⚙️ Architecture Overview

The system follows a modular monolith architecture (scalable to microservices later):

Backend Modules:
- auth
- users
- tracks
- uploads
- streaming
- playlists
- comments
- likes
- followers
- notifications
- search
- feed
🎧 Audio Processing Pipeline
User uploads audio file
File stored in Cloudflare R2
Background job triggered (BullMQ)
FFmpeg processes:
Audio normalization
Compression
Waveform generation
Processed file becomes available for streaming
📱 App Structure (Flutter)

Feature-based architecture:

features/
  auth/
  profile/
  player/
  feed/
  tracks/
  playlists/
  comments/
  notifications/
🌐 Web Structure (Next.js)

Routes:

/ → Feed
/profile/[username]
/track/[id]
/playlist/[id]
/upload
/search
📦 Development Roadmap
Phase 1 (MVP - 2 to 4 months)
Auth system
Upload system
Music player
Social interactions
Basic feed
Search
Phase 2
Better feed ranking
Notifications improvement
UI/UX polish
Phase 3
Recommendation system
Creator analytics
Monetization features
🧠 Design Philosophy
Mobile-first
Social-first (not music-only)
Fast iteration over perfection
Modular architecture
Real user feedback driven development
⚠️ Important Notes
This project is under active development
Architecture is designed to scale gradually
MVP focuses on speed of launch, not perfection
📬 Contact


#Example for build

apt update
apt install -y wget unzip zip openjdk-17-jdk curl

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

cd ~
wget https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.1-stable.tar.xz
tar xf flutter_linux_3.32.1-stable.tar.xz
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
git config --global --add safe.directory /root/flutter
flutter --version

mkdir -p ~/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip -d ~/Android/Sdk/cmdline-tools/
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest

echo 'export ANDROID_SDK_ROOT=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc
source ~/.bashrc

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"

flutter config --android-sdk ~/Android/Sdk
flutter doctor --android-licenses 2>/dev/null | tail -3

git clone https://github.com/mr4rahimi/flmusic.git
cd flmusic/apps/mobile
flutter pub get

flutter build apk --release --split-per-abi



## For collaboration or inquiries:
📧 +989916352600 
telegram or whatsapp

📄 License

This project is currently private / proprietary unless stated otherwise.