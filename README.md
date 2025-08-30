# RISC-V_RV32I_CPU
본 프로젝트는 RV32I 명령어 집합을 지원하는 RISC-V CPU를 직접 설계하고,  
단일 사이클(Single Cycle) 및 다중 사이클(Multi Cycle) 구조를 구현·비교한 시스템입니다.  
Verilog/SystemVerilog로 작성하고 Vivado 및 시뮬레이션 환경에서 검증하였습니다.

<br>

## 주요 기능
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

## 개발 환경
| 항목        | 내용 |
|-------------|------|
| 수행 기간   | 2025.08.11 ~ 2025.08.24 |
| 개발 언어   | SystemVerilog |
| 개발 환경  | VSCode, C, Assembly |
| 시뮬레이션  | Vivado Simulator |


<br>

## RISC-V란?
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

## RV32I Architecture
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

###  CPU Block Diagram
<img width="1000" alt="image" src="https://github.com/user-attachments/assets/f99b90cd-843d-4b39-9695-2264d6ca70e3" />

**- CPU 동작 단계를 Fetch → Decode → Excute → MemAccess → Write Back 순서로 구현**

---

### CPU FSM
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


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
| ADD x4, x1, x2  | 11 + 12           | **23**  |
| SUB x5, x1, x2  | 11 - 12           | **-1**  |
| SLL x6, x1, x2  | 11 << 12          | **45056** |
| SLT x7, x1, x2  | (11 < 12) ? 1 : 0 | **1 (True)** |
| SLTU x8, x1, x2 | (11 < 12, Unsigned) | **1** |
| XOR x9, x1, x2  | 11 ^ 12           | **7** |
| SRL x10, x1, x2 | 11 >> 12          | **0** |
| SRA x11, x1, x2 | 11 >>> 12         | **0** |
| OR x12, x1, x2  | 11 \| 12          | **15** |
| AND x13, x1, x2 | 11 & 12           | **8** |  

- ROM에 다양한 R-Type 명령어를 저장하고 실행한 결과, 연산 값이 정상적으로 레지스터에 기록되는 것을 확인  

---

### I-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/6f12b56d-26bd-4409-99ad-8cc974d8c483" />   


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
| ADDI x14, x1, 4  | 11 + 4   | **15** |
| SLTI x15, x1, 4  | 11 < 4   | **0 (False)** |
| SLTIU x16, x1, 4 | 11 < 4 (Unsigned) | **0 (False)** |
| XORI x17, x1, 4  | 11 ^ 4   | **15** |
| ORI x18, x1, 4   | 11 \| 4  | **15** |
| ANDI x19, x1, 4  | 11 & 4   | **0** |
| SLLI x20, x1, 4  | 11 << 2  | **44** |
| SRLI x21, x1, 4  | 11 >> 2  | **2** |
| SRAI x22, x1, 4  | 11 >>> 2 | **2** |  

- 시뮬레이션 결과, 모든 I-Type 명령어가 정상적으로 동작하며, 연산 값이 목적지 레지스터에 기록됨을 확인   

---

### S-Type Simulation
<img width="800" alt="image" src="https://github.com/user-attachments/assets/178e1fec-5e27-452e-bccd-fe4215fb70a4" />   


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
|sw x4, 0(x1) |M[rs1 + imm][0:31] = rs2[0:31] | **00000017** |
|sb x5, 4(x1) |M[rs1 + imm][0:15] = rs2[0:15] | **xxxxxxff** |
|sh x6, 8(x1) |M[rs1 + imm][0:7] = rs2[0:7] | **xxxxb000** |  

- sw는 x4의 전체 32비트, sb는 x5의 하위 8비트, sh는 하위 16비트를 RAM에 저장하는 것을 확인  

---

### L-Type Simulation
<img width="800"   src="https://github.com/user-attachments/assets/2df02b6b-d625-473f-ba7c-90edc9cdc5d3" />   


| 명령어 | 연산식              | 결과 값 |
|--------|---------------------|---------|
|lb, x23. 0(x1) | x23 = M[11 + 0][0:7] | **00000017** |
|lh, x24. 4(x1) | x24 = M[11 + 4][0:15] | **xxxxxxff** |
|lw, x25. 8(x1) | x25 = M[11 + 8][0:31] | **xxxxb000** |
|lbu, x26. 4(x1) | x26 = M[11 + 4][0:7] (unsigned) | **000000ff** |
|lhu, x27. 8(x1) | x27 = M[11 + 8][0:15] (unsigned) | **0000b000** |  

- RAM에서 1바이트(lb/lbu), 2바이트(lh/lhu), 4바이트(lw)를 읽어와 부호 확장 또는 0 확장 후 레지스터에 저장되는 것을 확인

---

### B-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/143d3efc-2857-4df6-9c8c-41a1f74a600d" />  


| 명령어             | 연산식                 | 조건 결과 | PC 변화  |
| --------------- | ------------------- | ----- | ------ |
| beq x1, x1, +8  | 11 == 11          | True  | **4 → 12 (PC + 8)** |
| bne x1, x2, +8  | 11 != 12            | True  | **12 → 20 (PC + 8)** |
| blt x1, x2, +8  | 12 < 11             | False | **20 → 24 (PC + 4)** |
| bge x1, x2, +8  | 12 >= 11            | True  | **32 → 40 (PC + 8)** |
| bltu x1, x2, +8 | 12 < 11 (unsigned)  | False | **40 → 44 (PC + 4)** |
| bgeu x1, x2, +8 | 12 >= 11 (unsigned) | True  | **52 → 60 (PC + 8)** |  

- 두 레지스터 값을 조건에 따라 비교하여 참일 경우 PC가 imm만큼 분기되고, 거짓일 경우 PC가 +4 증가하는 것을 확인

---

### U-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/846e9da1-5b58-473f-bf79-0d1a39dfaae5" />  

| 명령어          | 연산식                  | 결과 값 | PC 변화       |
| ------------ | -------------------- | ---- | ----------- |
| lui x28, 1   | (1 << 12)            | **4096** | **0x88 → 0x8C** |
| auipc x29, 1 | PC(0x88) + (1 << 12) | **4232** | **0x8C → 0x90** |  

- 상위 20비트 즉시값을 12비트 시프트해 사용하며, LUI는 (imm<<12), AUIPC는 (PC + imm<<12)로 계산됨을 확인  

---

### J-Type Simulation
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/a0372c3d-2461-43bf-aadc-bda7e18af6fa" />

| 명령어               | 연산식 (대입)                              | rd에 기록  | PC 변화                          |
| ----------------- | ------------------------------------- | ------- | ------------------------------ |
| jal x30, +4     | x30 = PC + 4 , PC = PC + 4        | **144** | **140 → 144** *(분기 but 다음 주소)* |
| jalr x31, 4(x1) | x31 = PC + 4 , PC = (x1 + 4) & ~1 | **148** | **144 → (x1 + 4) & \~1**       |

- rd에 항상 PC+4를 저장하고, JAL은 PC+imm로, JALR은 (rs1+imm)&~1로 점프함을 파형으로 확인

---

### Test Code    
<img width="513" height="366" alt="image" src="https://github.com/user-attachments/assets/f026e52f-f4db-4450-b844-3d3a6d1a945d" />  

- 위 C 코드의 Bubble Sort를  어셈블리 변환 → 머신 코드로 변환 후 CPU 테스트

<img width="800" height="127" alt="image" src="https://github.com/user-attachments/assets/581fd9a7-1d38-4796-a906-44c04703b8dc" />

- x54~x57 레지스터 값은 배열 요소를 나타내며, 교환 과정에서 값이 바뀌는 것을 확인 가능
버블 정렬 테스트 결과, 5,4,3,2,1 입력값이 비교와 교환 과정을 거쳐 최종적으로 1,2,3,4,5로 정렬됨을 확인

---

### Trouble Shooting
**Before** 
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/8e7235f3-2c14-4d06-beba-977deba3c7bc" />  

- JAL 명령어(0x020000ef)를 통해 adder 함수를 호출해야 했으나, 파형 확인 결과 PC가 분기하지 않고 +4 증가  
- 따라서 adder 함수가 실행되지 않고, 이후 명령(sw a0, -28(s0))이 곧바로 실행되면서 a0=64 값이 메모리에 저장되는 현상을 확인

<br>

**After**
<img width="800"  alt="image" src="https://github.com/user-attachments/assets/448544af-a21d-494a-a6e3-395cfd061905" />  

1. **제어 신호 레지스터화**  
   - `jal`, `jalr`, `branch` 신호를 파이프라인 레지스터에 저장해 한 사이클 지연시켜 EX 단계까지 동기화  
2. **레지스터 파일 신호 전달**  
   - `regFileWe`, `RFWDSrcMuxSel` 등 쓰기 관련 신호도 레지스터를 거쳐 전달  
3. **MUX 안정화**  
   - `PCSrcMuxSel` 계산 시 레지스터화된 신호를 사용하여 점프 타이밍 불일치 제거  

<br>

<img width="800"  alt="image" src="https://github.com/user-attachments/assets/e5375010-2582-4335-be61-41b357d7d074" />  

**결과**  
- JAL, JALR 명령어가 정상적으로 점프 수행  
- adder 함수로 정상 진입  
- 잘못된 Store 실행(a0=64 저장) 문제 해결  
- Multi-cycle 설계에서 단계 간 제어 신호 동기화의 중요성을 확인

---

## Conclusion

이번 프로젝트를 통해 RV32I CPU 아키텍처를 직접 설계하고 시뮬레이션을 통해 검증하면서, 명령어 타입별 동작과 멀티사이클 구조의 장단점을 깊이 이해할 수 있었다.  

특히 **트러블슈팅 과정**에서 JAL 명령어의 점프 타이밍 문제를 발견하고, 레지스터 삽입을 통한 제어 신호 동기화로 문제를 해결하며 단순한 기능 구현을 넘어 **구조적 완성도와 안정성 확보**의 중요성을 배웠다.    

이번 경험을 통해 얻은 지식과 문제 해결 역량은 향후 SoC 설계, 프로세서 최적화, 하드웨어 아키텍처 연구 등 더 복잡한 프로젝트에서도 직접적으로 활용할 수 있을 것이다.
