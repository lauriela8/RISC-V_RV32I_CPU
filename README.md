# 🚀 RISC-V_RV32I_CPU
본 프로젝트는 RV32I 명령어 집합을 지원하는 RISC-V CPU를 직접 설계하고,  
단일 사이클(Single Cycle) 및 다중 사이클(Multi Cycle) 구조를 구현·비교한 시스템입니다.  
Verilog/SystemVerilog로 작성하고 Vivado 및 시뮬레이션 환경에서 검증하였습니다.

<br>

## 🎯 주요 기능
- **RV32I 명령어 지원**
  - R-Type, I-Type, S-Type, B-Type, L-Type, U-Type, J-Type
- **CPU 구조**
  - Single Cycle CPU
  - Multi Cycle CPU (제어 FSM 기반)
- **메모리 연동**
  - Instruction ROM / Data RAM 설계 및 인터페이스
- **테스트 프로그램 실행**
  - C 코드 → Assembly → Machine Code 변환 → ROM에 로드
  - 버블 정렬 프로그램 실행 검증

<br>

## 🛠 개발 환경
| 항목        | 내용 |
|-------------|------|
| 수행 기간   | 2025.08.11 ~ 2025.08.24 |
| 개발 언어   | SystemVerilog |
| 개발 환경  | VSCode, C, Assembly |
| 시뮬레이션  | Vivado Simulator |


<br>

## ❔ RISC-V란?
• 명령어 실행 과정
    • 프로그램은 컴파일 후 명령어 메모리(ROM)에 저장되고
       CPU가 이를 불러와 파이프라인에서 처리

• 제어 유닛(Control Unit)
    • 명령어를 해석하여 레지스터 파일,ALU, 메모리로 제어 신호를 전달

• 레지스터 파일(Register File)
    • 연산에 필요한 데이터를 레지스터에서 읽고, ALU 연산 결과를 다시 저장

• 메모리 접근
    • Load/Store 명령 시 데이터 메모리(RAM)와 직접적으로 
       데이터 교환 수행

<br>

## ✅ RV32I Architecture
**Instruction Set**

<img width="800" alt="image" src="https://github.com/user-attachments/assets/207abac0-582c-493d-8d81-80f724b4d6d5" />

| 항목        | 내용 |
|-------------|------|
| opcode      | 명령어 타입 구분 |
| fun3, func7 | opcode 내에서 세부 연산 구분|
| rs1, rs2 | 연산에 필요한 값 |
| rd | 연산 결과가 저장될 목적지 레지스터 |
| imm(상수) | 연산이나 주소 계산에 바로 쓰이는 값 |

---

### ✅ CPU Block Diagram
<img width="1000" alt="image" src="https://github.com/user-attachments/assets/f99b90cd-843d-4b39-9695-2264d6ca70e3" />

**CPU 동작 단계를 Fetch → Decode → Excute → MemAccess → Write Back 순서로 구현**

---

### ✅ CPU FSM
<img width="500" alt="image" src="https://github.com/user-attachments/assets/9a531980-62e5-4cab-9326-2e4b942af644" />

| Type | 내용 |
|------|------|
|R-Type / I-Type / U-Type | EX 단계에서 연산 후 바로 결과 저장|
|S-Type | EX 상태에서 주소 계산 후 MEM 단계에서 메모리 쓰기|
| B-Type |  EX 상태에서 분기 조건 판단, PC 갱신 후 Fetch로 복귀 |
|L-Type| EX 상태에서 주소 계산 → MEM 상태에서 데이터 읽기 → WB 상태에서 레지스터에 저장 |
|J-Type| EX상태에서 PC 갱신 → WB 상태에서 rd에 PC + 4 저장|

---

### R-Type
<img width="1000"  alt="image" src="https://github.com/user-attachments/assets/ca800470-3093-4f68-ab77-f4cabc4a0049" />
<img width="800" height="571" alt="image" src="https://github.com/user-attachments/assets/c603f314-96f5-4d29-9ab3-97a50254f598" />

**R-Type은 레지스터 간 연산 명령어로, 두 소스 레지스터(rs1, rs2)의 값을 ALU가 연산하여 목적지 레지스터(rd)에 저장**  
**실행 단계:**  
**- Fetch/Decode:** ROM에서 명령어를 읽어 제어 신호를 생성  
**- Execute:** ALU가 rs1, rs2의 값을 받아 연산 후 결과를 레지스터(rd)에 저장  

### R-Type Simulation
<img width="800" height="1122" alt="image" src="https://github.com/user-attachments/assets/0c400194-faae-4876-8c64-9761247eda7c" />


ROM에 다양한 R-Type 명령어를 저장하고 실행한 결과, 연산 값이 정상적으로 레지스터에 기록되는 것을 확인했습니다.  

| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
| ADD x4, x1, x2  | 11 + 12           | 23  |
| SUB x5, x1, x2  | 11 - 12           | -1  |
| SLL x6, x1, x2  | 11 << 12          | 45056 |
| SLT x7, x1, x2  | (11 < 12) ? 1 : 0 | 1 (True) |
| SLTU x8, x1, x2 | (11 < 12, Unsigned) | 1 |
| XOR x9, x1, x2  | 11 ^ 12           | 7 |
| SRL x10, x1, x2 | 11 >> 12          | 0 |
| SRA x11, x1, x2 | 11 >>> 12         | 0 |
| OR x12, x1, x2  | 11 \| 12          | 15 |
| AND x13, x1, x2 | 11 & 12           | 8 |

파형에서도 각 명령어 수행 후 목적지 레지스터(rd)에 올바른 값이 기록됨을 확인할 수 있습니다.

---

### I-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/6f12b56d-26bd-4409-99ad-8cc974d8c483" />  


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
| ADDI x14, x1, 4  | 11 + 4   | 15 |
| SLTI x15, x1, 4  | 11 < 4   | 0 (False) |
| SLTIU x16, x1, 4 | 11 < 4 (Unsigned) | 0 (False)|
| XORI x17, x1, 4  | 11 ^ 4   | 15 |
| ORI x18, x1, 4   | 11 \| 4  | 15 |
| ANDI x19, x1, 4  | 11 & 4   | 0 |
| SLLI x20, x1, 4  | 11 << 2  | 44 |
| SRLI x21, x1, 4  | 11 >> 2  | 2 |
| SRAI x22, x1, 4  | 11 >>> 2 | 2 |

시뮬레이션 결과, 모든 I-Type 명령어가 정상적으로 동작하며, 연산 값이 목적지 레지스터에 기록됨을 확인할 수 있습니다.  

---

### S-Type Simulation
<img width="800" alt="image" src="https://github.com/user-attachments/assets/178e1fec-5e27-452e-bccd-fe4215fb70a4" />  


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
|sw x4, 0(x1) |M[rs1 + imm][0:31] = rs2[0:31] | 00000017|
|sb x5, 4(x1) |M[rs1 + imm][0:15] = rs2[0:15] | xxxxxxff|
|sh x6, 8(x1) |M[rs1 + imm][0:7] = rs2[0:7] |xxxxb000|  

각각 sw는 x4의 전체 32비트, sb는 x5의 하위 8비트, sh는 하위 16비트를 RAM에 저장하는 것을 확인할 수 있습니다. 

---

### L-Type Simulation
<img width="800"   src="https://github.com/user-attachments/assets/2df02b6b-d625-473f-ba7c-90edc9cdc5d3" />
| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
|lb, x23. 0(x1) | x23 = M[rs1 + 0][0:7]
|lh, x24. 4(x1) |
|lw, x25. 8(x1) |
|lbu, x26. 4(x1) |
|lhu, x27. 8(x1) |
---

### B-Type Simulation
<img width="800" alt="image" src="https://github.com/user-attachments/assets/37090314-aca9-41ee-b093-7b8252731b1e" />

---

### U-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/846e9da1-5b58-473f-bf79-0d1a39dfaae5" />

---

### J-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/a0372c3d-2461-43bf-aadc-bda7e18af6fa" />

---


