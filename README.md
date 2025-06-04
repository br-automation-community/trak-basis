# TrakBasis – ACOPOStrak Control Framework

**TrakBasis** is a modular and extensible control framework designed to simplify development with **ACOPOStrak** systems. It provides a robust foundation for managing power states, shuttle handling, motion commands, and diagnostics — covering the essential features required in any machine using ACOPOStrak.

This framework is especially suited for **closed-loop assemblies** using a **single sector as reference**, but is designed to be extended for more complex topologies.

---

## 🔧 Core Functionality

### 1. Power Management
TrakBasis manages power-on and power-off sequences for the ACOPOStrak assembly safely, ensuring readiness before enabling movement or interacting with hardware.

### 2. Shuttle Management
- **Simulation Support**: Automatically adds simulated shuttles when running in simulation mode.
- **Real Mode Detection**: Detects and registers real shuttles after startup.
- **ID Recovery**: Recovers shuttle identifiers after power loss using position-based matching.
- **Data Structure**: Provides shuttle status including position, velocity, segment, movement state, and lifecycle data.

### 3. Motion Control
- Supports **absolute positioning** and **velocity commands**.
- Allows external commands to be triggered in a centralized way through a shared interface structure.
- Handles collective halts and coordinated movement restarts.

### 4. Diagnostics & Error Handling
- Automatically detects and categorizes assembly, segment, or shuttle errors.
- Identifies the **initiator** of an error and fetches a descriptive message from the system logger.
- Supports targeted reset procedures per error type (assembly reset or per-shuttle reset).
- Provides structured diagnostic output (`ErrorID`, `ErrorText`, `ErrorInitiator`) for easy integration with HMIs or remote clients.

---

## ✅ Compatibility

TrakBasis is developed for and tested with:

- **Automation Studio 6.x**  
- **mappMotion 6.x**    

> 💡 All Automation Studio 6.x versions are supported.  
> ⚠️ Backporting to Automation Studio 4 is not supported due to structural and library differences.
