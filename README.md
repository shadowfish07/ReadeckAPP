# ReadeckApp

[English](./README.md) | [中文](./README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/shadowfish07/ReadeckApp)]()
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/shadowfish07/ReadeckAPP?utm_source=oss&utm_medium=github&utm_campaign=shadowfish07%2FReadeckAPP&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)
[![codecov](https://codecov.io/gh/shadowfish07/ReadeckAPP/branch/main/graph/badge.svg?token=nq9u4gyBBM)](https://codecov.io/gh/shadowfish07/ReadeckAPP)

A read-later mobile application built as a companion app for [Readeck](https://readeck.org/en/).

## About

Readeck is an excellent read-later project, but it doesn't provide mobile support. ReadeckApp aims to serve as its mobile companion, providing users with a convenient mobile read-later tool. Additionally, ReadeckApp extends functionality based on Readeck data, including daily reading features, AI translation, and more.

## ✨ Features

- **📱 Daily Reading**: Daily random selection of 5 unarchived articles with potential data visualization
- **🌐 Full Readeck Support**: Supports all Readeck web features (in development)
- **🔒 Complete Privacy**: No data sent to third parties - your data stays private
- **📊 Readeck-First Architecture**: Prioritizes Readeck data with appropriate local caching, avoiding data sync issues
- **🤖 AI Features**: AI translation, AI tagging, and more
- **📱 Android Native**: Built with Flutter for smooth Android experience

## 📋 Prerequisites

Before using ReadeckApp, you need to deploy your own Readeck instance. Follow the [official Readeck documentation](https://readeck.org/en/docs/) for setup instructions.

## 📦 Installation

### Download APK

1. Go to the [GitHub Releases](https://github.com/yourusername/ReadeckApp/releases) page
2. Download the latest APK file
3. Install the APK on your Android device

_Google Play Store release is planned for the future._

### Build from Source

```bash
# Clone the repository
git clone git@github.com:shadowfish07/ReadeckAPP.git
cd ReadeckApp

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Key Libraries**:
  - `go_router` - Navigation
  - `sqflite` - Local database
  - `freezed` - Code generation
  - `result_dart` - Error handling
  - `dio_socket_client` - Network requests
  - `flutter_command` - Command pattern
  - `flutter_html` - HTML rendering

## 🗺️ Roadmap

- [ ] Enhanced AI functionality
- [ ] Improved daily recommendations and summaries
- [ ] Google Play Store release
- [ ] iOS support
- [ ] Reading analytics and visualizations

## 🐛 Known Issues

This project is currently in early development stage. Please report any issues you encounter.

## 🤝 Contributing

Contributions are welcome! Please refer to `.trae/rules/project_rules.md` for detailed contribution guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Readeck](https://readeck.org/en/) - The excellent read-later service that inspired this project
- Flutter community for the amazing framework and packages

## Activity

![Alt](https://repobeats.axiom.co/api/embed/430e563b36a674be5e30f70f5991342c9488283a.svg "Repobeats analytics image")
