# FEP-NNNN: FlagQuantum - Multi-Chip Distributed Quantum Statevector Simulator

**Status:** `Implemented`

**Created:** 2026-05-25

**Owner:** @FlagQuantum

**SIG:** sig-ai4s

**Target Version:** FlagOS 2.1

---

## Summary

FlagQuantum is a high-performance distributed quantum statevector simulator built on PyTorch, leveraging `DTensor` from `torch.distributed` to enable quantum circuit simulation across multiple GPUs with automatic sharding and resharding. It provides a comprehensive gate set, invertible backpropagation, multiple data encoding schemes, and OpenQASM 3.0/2.0 export capability, allowing circuits to run on real quantum hardware including IBM Quantum, AWS Braket, Azure Quantum, IonQ, and Rigetti.

**Repository:** [github.com/flagos-ai/FlagQuantum](https://github.com/flagos-ai/FlagQuantum)

---

## Motivation

Quantum computing is transitioning from theoretical research to engineering practice, yet existing quantum simulation frameworks suffer from the following pain points:

1.  **Limited simulation scale:** A single GPU cannot hold large-scale quantum statevectors (n qubits require 2^n complex numbers), and existing frameworks lack efficient multi-GPU distributed simulation capabilities.
2.  **Disconnection from classical ML ecosystems:** Most quantum simulation frameworks are isolated from mainstream deep learning frameworks, requiring users to manually bridge gradient computation for quantum-classical hybrid algorithms (e.g., QML).
3.  **Poor hardware portability:** Migrating circuits across different quantum hardware platforms requires significant adaptation effort, with no unified intermediate representation export solution.
4.  **Insufficient extensibility:** Adding custom gate operations often requires modifying the framework core, hindering community contributions and domain-specific extensions.

FlagQuantum aims to address these issues by providing a PyTorch-integrated, horizontally scalable, and hardware-portable quantum simulation infrastructure for the FlagOS ecosystem.

### Goals

-   Provide a distributed quantum statevector simulator based on PyTorch DTensor, supporting multi-GPU automatic sharding and resharding
-   Implement a comprehensive quantum gate set (Pauli, Clifford, rotation, controlled gates) with both functional and operator-style invocation
-   Support invertible backpropagation for memory-efficient gradient computation in quantum circuits
-   Provide multiple classical data encoding schemes (angle, amplitude, basis, GeneralEncoder)
-   Support OpenQASM 3.0/2.0 export, compatible with major hardware platforms including IBM Quantum, AWS Braket, Azure Quantum, IonQ, and Rigetti
-   Support custom gate registration mechanism, enabling gate library extension without modifying core code
-   Include built-in measurement post-selection and depolarizing noise models
-   Provide quantum circuit visualization capabilities

### Non-Goals

-   No quantum compilation optimization passes (e.g., gate merging, circuit simplification) — deferred to future versions
-   No quantum error correction (QEC) simulation
-   No acceleration backends beyond GPU (e.g., FPGA, dedicated ASIC)
-   No quantum hardware drivers or direct hardware communication protocols
-   No high-level wrappers for variational quantum algorithms (e.g., out-of-the-box VQE, QAOA implementations) — only low-level building blocks are provided
-   No dynamic qubit allocation or mid-execution GPU scaling

---

## Proposal

From the user's perspective, FlagQuantum provides the following core workflows:

### 1\. Create a Distributed Quantum Device

Users create a quantum device via `DistributedQuantumDevice`, specifying the number of qubits, batch size, and GPU count. The framework automatically handles statevector sharding and distribution:

```python
import flagquantum as fq

qdev = fq.DistributedQuantumDevice(n_wires=4, bsz=2, world_sz=1, device='cuda')

```

### 2\. Build and Execute Quantum Circuits

Gates can be applied in either functional or operator style:

```python
# Functional style
fq.h(qdev, wires=[0])
fq.rx(qdev, wires=[1], params=0.5)
fq.cx(qdev, wires=[0, 1])

# Operator style
fq.H(wires=[0])(qdev)
fq.RX(wires=[1], init_params=torch.tensor([0.5]))(qdev)
fq.CNOT(wires=[0, 1])(qdev)

```

### 3\. Train Parameterized Quantum Circuits

Trainable parameters integrate seamlessly with PyTorch optimizers:

```python
rx_gate = fq.RX(wires=[0], trainable=True)
optimizer = torch.optim.Adam([rx_gate.params])

for _ in range(100):
    optimizer.zero_grad()
    qdev.reset_states()
    rx_gate(qdev)
    loss = fq.measure_allZ(qdev).sum()
    loss.backward()
    optimizer.step()

```

### 4\. Data Encoding

Embed classical data into quantum states:

```python
# Angle encoding
fq.angle_encoder(qdev, x, wires=[0, 1, 2, 3])

# Amplitude encoding
fq.amplitude_encoder(qdev, amplitudes)

# Custom encoding circuit
encoder = fq.GeneralEncoder([
    {"func": "ry", "wires": [0], "input_idx": 0},
    {"func": "ry", "wires": [1], "input_idx": 1},
    {"func": "cx", "wires": [0, 1]},
])
encoder(qdev, x)

```

### 5\. Export to Real Quantum Hardware

```python
qdev = fq.DistributedQuantumDevice(n_wires=3, record_op=True)
# ... build circuit ...
fq.export_to_qasm(qdev, "circuit.qasm", version=3.0)
# Submittable to IBM Quantum / AWS Braket / Azure Quantum / IonQ / Rigetti

```

### 6\. Multi-GPU Distributed Execution

```bash
torchrun --nproc_per_node=4 your_script.py

```

---

## Design Details

### Module Architecture

```
flagquantum/
├── devices/          # Quantum device implementations
│   └── distributed_device.py   # DistributedQuantumDevice core
├── drawer/           # Quantum circuit visualization
│   ├── mpl_drawer.py           # Matplotlib-based circuit renderer
│   ├── style.py                # Visualization style configuration
│   └── test_drawer.py          # Drawer test utilities
├── ops/              # Quantum operations
│   ├── functional.py           # Functional-style gate API (fq.h, fq.rx, ...)
│   ├── invertible.py           # Invertible backpropagation logic
│   ├── matrices.py             # Gate matrix implementations
│   ├── operator.py             # Operator-style gate classes (fq.H, fq.RX, ...)
│   └── registry.py             # Custom gate registration mechanism
├── encoding/         # Data encoding
│   └── encoder.py              # Angle, amplitude, basis encoding & GeneralEncoder
├── measurement/      # Measurement utilities
│   └── measure.py              # measure_allZ, post-selection, noise
└── utils/            # Helper functions
    ├── dtensor.py              # DTensor sharding/resharding utilities
    ├── interchange.py          # Data interchange
    └── qasm.py                 # OpenQASM 3.0/2.0 export

```

### Core Data Flow

```
User Code
  │
  ▼
DistributedQuantumDevice
  │  Maintains statevector as DTensor [bsz, 2^n_wires, real/imag]
  │  Automatically manages sharding strategy
  ▼
Gate Operations (ops/)
  │  Functional: fq.h(qdev, wires=[0])
  │  Operator:   fq.H(wires=[0])(qdev)
  │  Internally invokes DTensor reshard to optimize communication
  ▼
Measurement (measurement/)
  │  measure_allZ    → expectation value tensor
  │  post-selection  → conditional filtering
  │  depolarizing    → noise injection
  ▼
Backpropagation
  │  Standard mode:  PyTorch autograd
  │  Invertible mode: invertible=True, trades compute for memory
  ▼
Export (utils/qasm.py)
  └─→ OpenQASM 3.0 file → Hardware platforms

```

### DTensor Sharding Strategy

The statevector has shape `[bsz, 2^n_wires]` and is sharded along the second dimension (state space dimension) across `world_sz` GPUs. During gate operations:

-   **Local gates** (acting on a subset of qubits): executed directly on the corresponding shard, no inter-GPU communication required
-   **Non-local gates** (acting on qubits spanning shard boundaries): trigger automatic reshard, redistributing the statevector to an optimal shard layout before execution

### Custom Gate Registration Mechanism

```python
register_gate("my_gate", matrix)  # Register a 2x2 unitary matrix
# Automatically generates:
#   fq.ops.registry.my_gate       — functional interface
#   fq.ops.registry.my_gate_inv   — inverse gate
#   fq.ops.registry.MY_GATE       — operator class

```

### Invertible Backpropagation

When `invertible=True`, intermediate statevectors are not saved during forward propagation. Instead, they are recomputed during backward propagation by applying inverse gates, trading compute for memory. This is suitable for deep circuits or large batch scenarios.

---

## Packaging

### Build Commands

```bash
# Install from source
git clone https://github.com/flagos-ai/FlagQuantum.git
cd FlagQuantum
pip install .

```

### Package Format

-   **PyPI distribution:** `pip install flagquantum`

### Platform Requirements

| Dependency | Minimum Version | Notes |
| --- | --- | --- |
| Python | ≥ 3.10 | Uses match syntax and other new features |
| PyTorch | ≥ 2.5.0 | Required for DTensor support |
| NumPy | ≥ 1.24.0 | Auxiliary numerical computation |

### Optional Dependencies

| Group | Package | Purpose |
| --- | --- | --- |
| `[viz]` | matplotlib ≥ 3.5.0 | Circuit visualization |
| `[invertible]` | PyTorch ≥ 2.5.0 (nightly recommended) | Invertible backpropagation |
| `[dev]` | pytest, ruff, black, mypy | Development and testing |
| `[all]` | All of the above | Complete installation |

### CI/CD

-   Test framework: `pytest`, with markers `slow` / `gpu` / `distributed`
-   Run command: `python run_tests.py`
-   Code style: `ruff` + `black` (line-length=88)
-   Type checking: `mypy` (`ignore_missing_imports=true`)

---

## Test Plan

### Functional Tests

All 77 tests passing (duration: 10.81s). Each goal below lists its verifying test suite and cases.

#### Goal 1: Distributed statevector simulation with multi-GPU automatic sharding and resharding

`test_device.py` (9 cases):

| Test Case | Description |
| --- | --- |
| `test_cpu_device` | Device creation and basic operations on CPU |
| `test_cuda_device` | Device creation and basic operations on CUDA |
| `test_reset_states` | State reset to zero state |
| `test_bsz_change` | Batch size modification |
| `test_load_amplitudes` | Loading custom amplitude vectors |
| `test_canonicalize` | State canonicalization |
| `test_probability_sum` | Total probability sums to 1 |
| `test_zero_state_probability` | Zero-state probability correctness |
| `test_device_properties` | Device property accessors |

`distributed/test_quantum_device.py` (3 cases):

| Test Case | Description |
| --- | --- |
| `test_groupings` | Qubit grouping for sharding |
| `test_dqd` | DistributedQuantumDevice end-to-end |
| `test_grads` | Gradient computation on distributed device |

#### Goal 2: Comprehensive gate set with functional and operator-style invocation

`test_gates.py` (15 cases):

| Test Case | Description |
| --- | --- |
| `test_hadamard` | Hadamard gate output state |
| `test_pauli_x` | Pauli-X gate output state |
| `test_pauli_z` | Pauli-Z gate output state |
| `test_rx_rotation` | RX rotation gate |
| `test_ry_rotation` | RY rotation gate |
| `test_rz_gate` | RZ rotation gate |
| `test_x_gate_identity` | X gate identity property |
| `test_cnot` | CNOT gate (control=1) |
| `test_cnot_control_0` | CNOT gate (control=0) |
| `test_swap` | SWAP gate |
| `test_bell_state` | Bell state preparation |
| `test_parameter_gradient` | Parameterized gate gradient flow |
| `test_parameter_value_change` | Parameter value update propagation |
| `test_inverse_gate` | Gate inverse correctness |
| `test_x_and_z_anticommute` | X/Z anticommutation relation |

#### Goal 3: Invertible backpropagation for memory-efficient gradient computation

`distributed/test_quantum_gradients.py` (1 case):

| Test Case | Description |
| --- | --- |
| `test_inv` | Invertible backpropagation gradient correctness |

#### Goal 4: Multiple classical data encoding schemes (angle, amplitude, basis, GeneralEncoder)

`test_encoding.py` (10 cases):

| Test Case | Description |
| --- | --- |
| `test_angle_encoder` | Angle encoding correctness |
| `test_encoder_with_cx` | Encoder with CNOT entanglement |
| `test_encoder_inverse` | Encoder inverse operation |
| `test_angle_encoder_convenience` | Angle encoder convenience API |
| `test_amplitude_encoding` | Amplitude encoding correctness |
| `test_complex_amplitudes` | Complex amplitude support |
| `test_amplitude_encoding_shape` | Amplitude encoding output shape |
| `test_create_angle_circuit` | Angle circuit construction |
| `test_create_basis_circuit` | Basis circuit construction |
| `test_create_angle_circuit_different_features` | Angle circuit with varying feature count |

`distributed/test_quantum_device.py` (1 case):

| Test Case | Description |
| --- | --- |
| `test_encoder` | Encoding on distributed device |

#### Goal 5: OpenQASM 3.0/2.0 export compatible with major hardware platforms

`test_qasm_exporter.py` (22 cases):

| Test Case | Description |
| --- | --- |
| `test_export_qasm3_format` | QASM 3.0 format export |
| `test_export_qasm2_format` | QASM 2.0 format export |
| `test_unified_export_qasm3` | Unified export API (v3) |
| `test_unified_export_qasm2` | Unified export API (v2) |
| `test_unified_export_invalid_version` | Invalid version rejection |
| `test_parameterized_gates_qasm3` | Parameterized gates in QASM 3.0 |
| `test_parameterized_gates_qasm2` | Parameterized gates in QASM 2.0 |
| `test_rxx_decomposition_qasm3` | RXX gate decomposition (QASM 3.0) |
| `test_ryy_decomposition_qasm3` | RYY gate decomposition (QASM 3.0) |
| `test_rzz_decomposition_qasm3` | RZZ gate decomposition (QASM 3.0) |
| `test_controlled_rotation_decomposition_qasm3` | Controlled rotation decomposition |
| `test_multi_qubit_gates_qasm3` | Multi-qubit gates (QASM 3.0) |
| `test_multi_qubit_gates_qasm2` | Multi-qubit gates (QASM 2.0) |
| `test_single_qubit_gates_qasm3` | Single-qubit gates (QASM 3.0) |
| `test_empty_circuit` | Empty circuit export |
| `test_unknown_gate_handling` | Unknown gate fallback handling |
| `test_cnot_alias_handling` | CNOT/CX alias resolution |
| `test_export_to_qasm_file` | File-based export |
| `test_export_to_qasm_str` | String-based export |
| `test_single_wire_formatting` | Single wire formatting |
| `test_multiple_wires_formatting_qasm3` | Multi-wire formatting (QASM 3.0) |
| `test_multiple_wires_formatting_qasm2` | Multi-wire formatting (QASM 2.0) |

#### Goal 6: Built-in measurement post-selection and depolarizing noise models

`test_measurement.py` (15 cases):

| Test Case | Description |
| --- | --- |
| `test_hadamard` | Hadamard measurement expectation |
| `test_pauli_x` | Pauli-X measurement expectation |
| `test_pauli_z` | Pauli-Z measurement expectation |
| `test_rx_rotation` | RX rotation measurement |
| `test_ry_rotation` | RY rotation measurement |
| `test_x_gate_identity` | X identity measurement |
| `test_cnot` | CNOT measurement |
| `test_cnot_control_0` | CNOT (control=0) measurement |
| `test_swap` | SWAP measurement |
| `test_bell_state` | Bell state measurement |
| `test_parameter_gradient` | Parameterized measurement gradient |
| `test_parameter_value_change` | Parameter update in measurement |
| `test_inverse_gate` | Inverse gate measurement |
| `test_rz_gate` | RZ measurement |
| `test_x_and_z_anticommute` | Anticommutation in measurement |

`distributed/test_quantum_device.py` (1 case):

| Test Case | Description |
| --- | --- |
| `test_noisy_meas` | Noisy measurement with depolarizing noise |

### Compatibility Tests

| Feature | NVIDIA | Hygon | MUSA |
| :--- | :---: | :---: | :---: |
| Quantum Device | ✓ | ✓ | ✓ |
| Distributed Device | ✓ | ✓ | ✓ |
| Invertible Backpropagation | ✓ | ✓ | ✓ |
| Measurement | ✓ | ✓ | ✓ |
| Data Encoding | ✓ | ✓ | ✓ |
| OpenQASM Export | ✓ | ✓ | ✓ |
---

## Related PRs

-   [ ]  flagos-ai/FlagQuantum#1 — Initial repository commit: core modules (devices, ops, encoding, measurement, utils)
-   [ ]  flagos-ai/FlagQuantum#2 — Circuit visualization module (drawer) and tutorials (00–05)
-   [ ]  flagos-ai/FlagQuantum#3 — OpenQASM 3.0/2.0 export functionality

---

## Implementation History

| Date | Milestone |
| --- | --- |
| 2026-05-25 | FEP created|