<h1 align="center">
    <img src="./Screenshots/hero.png" alt="String">
</h1>

<p align="center">
  <i align="center">Take better notes, <b>link ideas</b>, and build a lasting knowledge base.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-Swift-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS-blue" alt="Platform">
  <img src="https://img.shields.io/github/stars/tagocms/WWDC2026-String" alt="GitHub Stars">
</p>

## Introduction

String is an **iOS and iPadOS app** built on Swift Playgrounds for the **Swift Student Challenge 2026**.

Designed for users unfamiliar with advanced note-taking tools, String brings the power of a **Zettelkasten system** to everyone — with a strong focus on accessibility and an intuitive, gesture-driven interface. Create notes, link them visually, and organize everything into nested slipboxes.

## Screenshots

<details open>
<summary>Screenshots</summary>
<br />

<p align="center">
    <img width="49%" src="./Screenshots/ss_1.png" alt="Onboarding: welcome screen introducing String's features"/>
&nbsp;
    <img width="49%" src="./Screenshots/ss_2.png" alt="Map View: notes arranged spatially on a zoomable canvas"/>
</p>
<p align="center">
    <img width="49%" src="./Screenshots/ss_3.png" alt="Note Editor: rich text editor with inline links and tags"/>
&nbsp;
    <img width="49%" src="./Screenshots/ss_4.png" alt="List View: accessible note list with VoiceOver support"/>
</p>

</details>

## Development

- **Architecture & Patterns**: The project uses **MVVM** to separate UI from business logic, with SwiftData handling persistence via `@Model` classes (`Note`, `Slipbox`, `Tag`) and their bidirectional relationships.
- **Frameworks**: Built entirely with **SwiftUI** and **SwiftData**. Custom `UIGestureRecognizer` subclasses power the multi-touch canvas — supporting simultaneous pan, pinch, and rotate gestures for the Map View.
- **Accessibility**: A core design pillar. The app adapts its entire layout for **VoiceOver** (switching from Map View to a fully accessible List View), and exposes meaningful labels and hints for every interactive element.

## License

String is available under the [MIT License](./LICENSE).
