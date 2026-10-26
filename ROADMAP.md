## API Stability

The project will be considered stable when all planned native APIs have been implemented and tested.

Until then, I’ll do my best to keep the APIs stable, but they may still change before Lunar Plasma is released.

## Status legend

- <img src="./resources/status-completed.svg" width="16" height="16" alt="Completed"> Completed
- <img src="./resources/status-development.svg" width="16" height="16" alt="In development"> In development
- <img src="./resources/status-planned.svg" width="16" height="16" alt="Planned"> Planned

## Roadmap

### In development / Planned

| Status | Area | Goal | Description |
|:---:|---|---|---|
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Customize appearance | Manage appearance settings: cursor theme, icon theme, application style, window decorations, etc. |
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Manage Wi-Fi networks | The active network can already be inspected, but nearby networks cannot yet be listed or managed. List nearby networks and connect to or disconnect from them |
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Manage Bluetooth devices | Known and connected devices can already be listed, but individual devices cannot yet be managed. Pair, connect to, disconnect from, and remove devices |
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Lock the screen | Lock the current Plasma session on demand |
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Play arbitrary sound files | Play a selected audio file through the default output device |
| <img src="./resources/status-development.svg" width="24" height="24" alt="In development"> | API | Manage microphones | List input devices, select the default, and control volume and mute |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Manage virtual desktops | List, create, remove, and switch virtual desktops |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Launch and close applications | Launch desktop applications and close selected running instances |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Desktop effects control API | List, enable, and disable supported KWin effects |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Window control API | Inspect, focus, move, resize, and close windows |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Active programs/processes/services detection API | Identify active applications, processes, and services |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | Backend | Replace the Bash backends with a lightweight executable | Keep the Lua API while moving backend operations into one executable |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | Documentation | Document integration with other languages | Provide examples for calling Lunar Plasma from other languages |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | Automation | Implement an automation framework for events and schedules | Run user-defined actions when events occur or schedules are due |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | API | Implement user modules | Load custom modules without modifying the core library |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | Interpreter | Implement an interpreter for running one-shot commands | Run API actions from a command line without writing a Lua script |
| <img src="./resources/status-planned.svg" width="24" height="24" alt="Planned"> | Documentation | Improve the documentation | Clarify setup, API behavior, and examples |

### Completed

| Status | Area | Goal |
|:---:|---|---|
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Streamline API access |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the sound API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the notifications API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the KDE desktop API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the power management API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the keyboard API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the Wi-Fi API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement the Bluetooth API |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement display inspection |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | API | Implement battery and power-source inspection |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | Testing | Implement a test suite |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | Documentation | Document the project |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | Documentation | Document the expanded APIs |
| <img src="./resources/status-completed.svg" width="24" height="24" alt="Completed"> | Documentation | Convert the project documentation into a GitHub wiki |
