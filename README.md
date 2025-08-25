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
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/5a05787f-e4ac-4082-a793-8def76af8ef5" />

---


