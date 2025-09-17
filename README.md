# TrakBasis – ACOPOStrak Control Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Automation Studio](https://img.shields.io/badge/Automation%20Studio-6.x-blue)](https://www.br-automation.com/)
[![mappMotion](https://img.shields.io/badge/mappMotion-6.x-green)](https://www.br-automation.com/)

**TrakBasis** is a modular and extensible control framework designed to simplify development with **ACOPOStrak** systems. It provides a robust foundation for managing power states, shuttle handling, motion commands, and diagnostics — covering the essential features required in any machine using ACOPOStrak.

This framework is especially suited for **closed-loop assemblies** using a **single sector as reference**, but is designed to be extended for more complex topologies.

## 📋 Table of Contents

- [What is ACOPOStrak?](#-what-is-acopostrak)
- [Core Functionality](#-core-functionality)
- [Getting Started](#-getting-started)
- [Usage Examples](#-usage-examples)
- [Project Structure](#-project-structure)
- [Control Interface](#️-control-interface)
- [Compatibility](#-compatibility)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 What is ACOPOStrak?

**ACOPOStrak** is B&R's intelligent track system that enables flexible transport solutions in automation. It uses magnetic shuttles that move independently along segments, offering:

- **Flexible Motion**: Independent shuttle control with precise positioning
- **Scalable Design**: Modular track segments for custom layouts
- **High Performance**: Fast acceleration and precise control
- **Energy Efficient**: Optimized power management across the system

**Why TrakBasis?**

Every ACOPOStrak project requires the same fundamental procedures:
- **Power Management**: Safe power-on/off sequences
- **Recovery Maneuvers**: Shuttle detection and ID recovery after power loss
- **Error Handling**: Assembly, segment, and shuttle error management
- **Motion Control**: Basic movement commands and coordination

**TrakBasis implements all these common procedures**, providing a ready-to-use foundation that eliminates repetitive development work and ensures proven, reliable operation patterns.

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
- Provides structured diagnostic output (`ErrorInfo.ID`, `ErrorInfo.Text`, `ErrorInfo.Initiator`) for easy integration with HMIs or remote clients.

---

## 🚀 Getting Started

### Prerequisites

Before using TrakBasis, ensure you have:

- **Automation Studio 6.x** installed
- **mappMotion 6.x** license
- **ACOPOStrak hardware** (or simulation environment)
- Basic knowledge of **Structured Text (ST)** programming

### Installation & Setup

> ⚠️ **Note**: This repository is for development and testing of TrakBasis itself. For use in your projects, download the latest release package.

#### Step 1: Import TrakBasis Package

1. **Download** the latest release package from the [Releases](../../releases) section
2. **Open** your existing Automation Studio project
3. **Import the package**:
   - Go to **Project** → **Import...**
   - Select the downloaded TrakBasis package file
   - Follow the import wizard to add all required files to your project

#### Step 2: Configure Hardware References

Update the `Reference.st` file to match your ACOPOStrak hardware configuration:

```st
// Update these lines to match your hardware configuration
AdrAssembly := ADR(gAssembly_1);        // Your assembly name
AdrSector := ADR(Sector_1);             // Your default sector name
AssemblyName := 'gAssembly_1';          // Assembly identifier
```

#### Step 3: Hardware Configuration

Ensure your ACOPOStrak hardware is properly configured in the **Physical View**:
- Assembly configuration matches your physical setup
- Sectors and segments are properly defined
- mappMotion configuration is deployed to the target

#### Step 4: Start Using TrakBasis

```st
// Wait for system ready, then power on the assembly
IF gTrakCtrl.Status.ReadyForPowerOn THEN
    gTrakCtrl.Command.Power := TRUE;
END_IF

// Check if assembly is powered on and ready for operation
IF gTrakCtrl.Status.PowerOn THEN
    // Assembly is powered and ready for shuttle operations
    // Keep Command.Power := TRUE as long as system should remain energized
END_IF
```

## 💡 Usage Examples

### Basic Assembly Control

```st
// Wait for system ready, then power on the assembly
IF gTrakCtrl.Status.ReadyForPowerOn THEN
    gTrakCtrl.Command.Power := TRUE;
END_IF

// Check if assembly is powered on and ready for operation
IF gTrakCtrl.Status.PowerOn THEN
    // Assembly is powered and ready for shuttle operations
    // Keep Command.Power := TRUE as long as system should remain energized
END_IF
```

### Shuttle Movement (All Shuttles)

```st
// Configure movement parameters
gTrakCtrl.Parameter.Position := 1.5;           // meters
gTrakCtrl.Parameter.Speed := 1.0;              // m/s  
gTrakCtrl.Parameter.Acceleration := 5.0;       // m/s²
gTrakCtrl.Parameter.Deceleration := 5.0;       // m/s²
gTrakCtrl.Parameter.Direction := mcDIR_POSITIVE;

// Ensure assembly is powered on before movement
IF gTrakCtrl.Status.PowerOn THEN
    // Move all shuttles to absolute position (elastic movement)
    gTrakCtrl.Command.Move.Absolute := TRUE;
    
    // Or move all shuttles with velocity
    // gTrakCtrl.Command.Move.Velocity := TRUE;
    
    // Stop all shuttle movements
    // gTrakCtrl.Command.Move.Halt := TRUE;
END_IF
```

### Error Handling

TrakBasis provides separate error handling for hardware and application errors:

```st
// Check for hardware errors (assembly, segment, shuttle)
IF gTrakCtrl.Status.Error THEN
    // Get hardware error information from Status.ErrorInfo
    ErrID := gTrakCtrl.Status.ErrorInfo.ID;
    ErrText := gTrakCtrl.Status.ErrorInfo.Text;
    ErrInitiator := gTrakCtrl.Status.ErrorInfo.Initiator;

    // Reset hardware errors
    gTrakCtrl.Command.ErrorReset := TRUE;
END_IF

// Check for application-level warnings (configuration, logic warnings)
IF gTrakCtrl.Status.Warning THEN
    // Get application warning information from Status.WarningInfo
    WID := gTrakCtrl.Status.WarningInfo.ID;
    WText := gTrakCtrl.Status.WarningInfo.Text;
    WState := gTrakCtrl.Status.WarningInfo.TrakState;

    // Acknowledge the warning once the operator has reviewed it
    // This does not reset hardware errors — use ErrorReset for hardware faults
    gTrakCtrl.Command.WarningAcknowledge := TRUE;
END_IF
```

### Shuttle Recovery Configuration

```st
// Configure shuttle recovery parameters
gTrakCtrl.Parameter.RestoreEnabled := TRUE;      // Enable position restoration
gTrakCtrl.Parameter.RestoreTolerance := 0.01;    // meters tolerance for recovery

// Check recovery status
IF gTrakCtrl.Status.ShRecoveryInfo.ShuttleRecovered THEN
    // Shuttle ID recovery was successful
END_IF

IF gTrakCtrl.Status.ShRecoveryInfo.ShuttleMoved THEN
    // Recovery not possible - shuttles were moved
END_IF
```

## 📁 Project Structure

```
TrakBasis/
├── Logical/
│   ├── Global.typ              # Global type definitions
│   ├── Global.var              # Global variables
│   ├── Libraries/              # External library dependencies
│   └── TrakBasis/
│       ├── TrakBasis.typ       # Main type definitions
│       ├── TrakBasis.var       # Configuration variables
│       └── TrakCtrl/
│           ├── TrakCtrl.st     # Main control program
│           ├── Commands.st     # Command handling
│           ├── Reference.st    # Reference management
│           ├── InitSequence.st # Initialization logic
│           ├── TrakCtrl.typ    # Control type definitions
│           └── TrakCtrl.var    # Control variables
├── Physical/                   # Hardware configuration
└── README.md
```

## 🎛️ Control Interface

TrakBasis provides a global control variable `gTrakCtrl` that serves as the main interface for all operations.

### Global Control Variable

```st
// Access the TrakBasis control interface anywhere in your project
gTrakCtrl : TrakCtrlType;
```

### Command Interface

Use `gTrakCtrl.Command` to control the system:

| Command | Type | Description |
|---------|------|-------------|
| `Power` | BOOL | Powers on/off the ACOPOStrak assembly (must remain TRUE while powered) |
| `Move.Absolute` | BOOL | Moves all shuttles to absolute position (elastic movement) |
| `Move.Velocity` | BOOL | Moves all shuttles with velocity within predefined sector |
| `Move.Halt` | BOOL | Stops the movement for all shuttles |
| `ErrorReset` | BOOL | Resets assembly errors |
| `WarningAcknowledge` | BOOL | Acknowledge application warnings |

### Parameter Interface

Configure movement and system parameters via `gTrakCtrl.Parameter`:

| Parameter | Type | Description |
|-----------|------|-------------|
| `Position` | LREAL | Target position for movement commands (meters) |
| `Speed` | REAL | Movement velocity (m/s) |
| `Acceleration` | REAL | Movement acceleration (m/s²) |
| `Deceleration` | REAL | Movement deceleration (m/s²) |
| `Direction` | McDirectionEnum | Movement direction (mcDIR_POSITIVE/mcDIR_NEGATIVE) |
| `RestoreEnabled` | BOOL | Enable shuttle position restoration after power-on |
| `RestoreTolerance` | LREAL | Position tolerance for shuttle recovery (meters) |

### Status Interface

Monitor system state through `gTrakCtrl.Status`:

| Status | Type | Description |
|--------|------|-------------|
| `CommunicationReady` | BOOL | Communication possible with assembly |
| `ReadyForPowerOn` | BOOL | Assembly can be powered on |
| `PowerOn` | BOOL | Assembly is powered on |
| `MovementDetected` | BOOL | Movements detected in assembly |
| `Error` | BOOL | Hardware error present in system |
| `Warning` | BOOL | Application-level warning present |

### Error & Warning Information

Access hardware error details via `gTrakCtrl.Status.ErrorInfo`:

| Error Info | Type | Description |
|------------|------|-------------|
| `ID` | DINT | Hardware error identifier |
| `Text` | STRING[255] | Human-readable error description |
| `Initiator` | STRING[32] | Component that caused the error |

Access application warning details via `gTrakCtrl.Status.WarningInfo`:

| Warning Info | Type | Description |
|--------------|------|-------------|
| `ID` | DINT | Application warning identifier |
| `Text` | STRING[255] | Human-readable warning description |
| `TrakState` | STRING[32] | TRAK state where the warning was triggered |

### Shuttle Data

Individual shuttle information is available in `gTrakCtrl.Status.Shuttle[index]`:

| Property | Type | Description |
|----------|------|-------------|
| `Valid` | BOOL | Shuttle data is valid |
| `ID` | UDINT | Shuttle identifier |
| `ActPosition` | LREAL | Current shuttle position (meters) |
| `ActVelocity` | REAL | Current shuttle velocity (m/s) |
| `ActSector` | STRING[32] | Current sector name |
| `TotalMoveDistance` | LREAL | Total distance moved by shuttle (meters) |

### Segment Data

Segment information is available in `gTrakCtrl.Status.Segment[index]`:

| Property | Type | Description |
|----------|------|-------------|
| `Valid` | BOOL | Segment data is valid |
| `Name` | STRING[32] | Segment name (for diagnostics) |
| `Info.TempBalancer` | REAL | Internal segment temperature |
| `Info.Voltage` | REAL | DC segment voltage |
| `Info.PowerConsumption` | REAL | Segment power consumption |

---

## ✅ Compatibility

TrakBasis is developed for and tested with:

- **Automation Studio 6.x**  
- **mappMotion 6.x**    

> 💡 All Automation Studio 6.x versions are supported.  
> ⚠️ Backporting to Automation Studio 4 is not supported due to structural and library differences.

---

## 🔧 Troubleshooting

### Common Issues

**Assembly won't power on**
- ✅ Verify hardware configuration matches physical setup
- ✅ Check that all segments are properly connected
- ✅ Ensure mappMotion configuration is deployed
- ✅ Verify no hardware errors in logger

**Shuttles not detected**
- ✅ Confirm shuttles are properly placed on track
- ✅ Check if running in simulation mode vs. real mode
- ✅ Verify assembly is fully powered before detection
- ✅ Review shuttle positioning and segment assignment

**Movement commands not executing**
- ✅ Ensure assembly is in ready state
- ✅ Check for active errors that block movement
- ✅ Verify shuttle ID exists and is valid
- ✅ Confirm position is within valid track range

**Simulation shuttles not appearing**
- ✅ Verify `DiagCpuIsSimulated()` returns TRUE
- ✅ Check simulation configuration in mappMotion
- ✅ Ensure assembly initialization completes successfully

### Getting Help

- 📖 **B&R Help**: Built-in Automation Studio help system
- 🌐 **B&R Community**: [community.br-automation.com](https://community.br-automation.com)
- 📧 **Issues**: Report bugs via GitHub Issues
- 📚 **Documentation**: ACOPOStrak and mappMotion user manuals

---

## 🤝 Contributing

We welcome contributions to improve TrakBasis! Here's how you can help:

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Guidelines

- Follow existing code style and conventions
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation as needed
- Keep commits focused and well-described

### Areas for Contribution

- 🔧 Additional motion commands and features
- 🧪 Test cases and validation scenarios
- 📖 Documentation improvements
- 🐛 Bug fixes and performance optimizations
- 🌐 Multi-sector and complex topology support

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **B&R Industrial Automation** for the ACOPOStrak technology and mappMotion framework
- **B&R Community** for feedback and contributions
- **Contributors** who help improve this framework

---

*Made with ❤️ by the B&R Community*
