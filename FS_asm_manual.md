# FurStack Assembly manual
This file describes architecture of FurStack Virtual Machine and assembly for it.

---

Content of the file:
1. Why use vm
2. Architecture of FurStack vm
3. Assembly for FurStack vm
4. Additional stuff

---

## 1. Why use vm
You probably wonder, why FurStack uses vm for executing the program instead of directly compiling to x86, arm, risc-v or any other existing architecture.
In nutshell, vm was created before the FurStack itself. FurStack was made with vm in mind. Another reason is complexity. All modern cpu architectures are a register machines
They aren't bad, but for stack-based language like FurStack, stack machine is a better fit. This makes compilation way simpler that trying to compile to x86.

## 2. architecture of FurStack vm
FurStack Virtual Machine is a 16-bit stack machine. This means that cpu architecture is based around the stack. A stack is a memory that works like a stack of plates.
You can put a value on top of it, which is called pushing and take from the top of it, which is called popping. Because of it the last value you push is the first value you pop.
FurStack vm has two of those. The first one is the data stack. You manipulate this one. The second one is the return stack. It's used for storing return addresses.
This allows for things like recursion, which is calling function from itself or using function inside another function. The return stack is connected to 20-bit program counter.
This allows for cpu of vm to access 1MB of program memory. Program counter (or pc for short) can be incremented by 1 or 3, depending on instruction and it can be changed.
Now lets get back to data stack. It's connected to various other components of the cpu. Those are registers, arithmetic logic unit (or alu for short) and compare unit.
Registers are connected to data stack. They can only store value popped from the data stack and push their value to the data stack. They mainly exist due to lack of swap and rot.
The alu does all the arithmetic and logic operations on the stack. I takes two top values from the stack and perform operations on them. Compare unit works almost like alu.
It takes the two top stack values and compares them. It return -1 if the condition is true. Otherwise it pushes 0. As mentioned previously, pc can increment by 1 or 3.
The lenght of the instructions is not constant. Some instructions take 3 bytes while most take 1 byte. Another componets outside cpu are program memory and main memory.
Program memory is 1MB of read only memory. It contains the compiled and assembled FurStack program. Main memory is the memory where variables are store and where devices are placed.
For now, vm has 64KB of random access memory, terminal and keyboard.

## 3. Assembly for FurStack vm
As you can see, compiler and assembler are separate. That's because assembler was created before the compiler. That also means one more thing.
If you don't value your sanity (or if you are a masochist), you can program FurStack vm in assembly. This gives access to some instructions that aren't used by compiler.

### Assembler related things

#### rem
The rem is used to define single line comment.

#### def `[name]` `[value]`
Def is used to define some values that could be used later in the assembly code. The values can be only a number between -32768 and 65535.
They can also be a fixed-point number between -128 and 127.996

#### deflab `[name]`
Deflab is used to define label. This is very useful when jumping, because you don't need to remember the exact address where you need to jump.

#### registers
There is 16 registers. All registers are labeled from reg0 to reg15

### Instructions and opcodes

#### nop
The noop does nothing for one cycle. It's not used by FurStack compiler.

#### alu `[fn]`
The alu instruction is the instruction for interacting with arithmetic logic unit. It has multiple opcodes that mean different operations. All of them work the same.
They take top two stack values, perform operation on them and push back the result. Top stack value goes to the right while next stack value goes to the left.
Below are the actual opcodes and their function numbers.

#### 0. add
Addition. Works with signed, unsigned and fixed-point numbers.

#### 1. sub
Subtraction. Works with signed, unsigned and fixed-point numbers.

#### 2. mul
Signed multiplication.

#### 3, mulu
Unsigned multiplication. It's not used by FurStack compiler.

#### 4. div
Signed division.

#### 5. divu
Unsigned division. It's not used by FurStack compiler.

#### 6. mod
Modulo operation. Remainder is always positive.

#### 7. fmul
Fixed-point multiplication. Fixed-point numbers have decimal point in fixed position. Below is the format of the numbers.
```
00000000.00000000
```
First 8 bits are the integer. The last 8 bits are the fraction. The number is signed.
The multiplication is performed like this.
result = (next `*` top) `>>` 8

#### 8. fdiv
Fixed-point division. It's performed like this.
result = (next `<<` 8) / top

#### 9. and
Bitwise and.

#### 10. or
Bitwise or.

#### 11. xor
Bitwise xor.

#### 12. nor
Bitwise nor. If two top stack values are equal, it works like not.

#### 13. sll
Shift left logical.

#### 14. srl
Shift right logical.

#### 15. sra
Shift right arithmetic.

#### push `[value]`
It pushes the value to the stack. It takes extra space. The value can be a signed, unsigned, fixed-point number or a definition.

#### drop
Discard the top stack value.

#### pur `[register]`
Push from register.

#### por `[register]`
Pop to register.

#### sw
Store word to the memory. It takes top stack value as value to store and value below as memory address.

#### lw
Load word from the memory. It takes top stack value as memory address.

#### dup
Push top stack value.

#### over
Push next stack value.

#### comp `[function]`
The comp is like alu instruction, but it interacts with compare unit. Below are the actual opcodes and their function numbers.

#### 0. eq
Check if equal.

#### 1. ne
Check if not equal.

#### 2. gt
Check if greater than. It uses signed comparison.

#### 3. ge
Check if greater than or equal. It uses signed comparison.

#### 4. lt
Check if less than. It uses signed comparison.

#### 5. le
Check if less than or equal. It uses signed comparison.

#### 6. gtu
Check if greater than. It uses unsigned comparison. It's not used by FurStack compiler.

#### 7. ltu
Check if less than. It uses unsigned comparison. It's not used by FurStack compiler.

#### j `[address]`
Jump to specified address or label. It uses extra space.

#### jc `[address]`
Jump to specified address or label, if the top stack value is not zero. It uses extra space.

#### cal `[address]`
Jump to specified address or label and store the return address to return stack. It uses extra space.

#### ret
Jump to top value in return stack.

#### exit
End the program.

## 4. Additional stuff
Memory map:
0x0000 - 0x7fff = 64KB RAM (read and write)
0x8000 - terminal (write only)
0x8001 - clear terminal (write only)
0x8002 - keyboard (read only)

Notes:
1. Assembled program is a text file, not a binary file. It's because I wanted to use it with a circuit simulator. I might change it later.
2. Instruction noop has code 0 and exit has 15. Yes, those instructions are written in asscending order from 0 to 15.
3. The vm might change in the future and memory map might also change in the future. Let's be hones, 16 bits is not a lot.
