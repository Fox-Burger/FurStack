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
FurStack uses virtual machine for executing it's code. You probably wonder why use vm when you could compile to x86 assembly. There are some reasons:
1. Complexity. x86 is a quite complex architecture that is register-based. FurStack virtual machine is much simpler architecture that is stack-based.
You can probably guess which one is simpler to compile to.
2. Portability. It's the same as with Java and interpreted languages. You can write your code once and it will run on any system.

Note that FurStack compiler and assembler will not work properly on Windows.

Also note that I might add more compile options to the language.

## 2. architecture of FurStack vm
FurStack virtual machine or fsvm for short, is a stack machine. Meaning the architecture is centred around the stack. There are three stacks in fsvm:
1. Data stack -  that's the one you mainly operate on.
2. Return stack - it's inaccessable by the programmer. It stores the return addresses.
3. Iteration stack - it's used for creating loops that will repeat specific ammount of times.
Data stack and return stack can store 262144 values and iteration stack can store 256 values. Data stack and iteration stack store 24-bit values.
Return stack can stack can store 28-bit values. This is caused by size of program counter, which is 28-bit. Because of this, fsvm has access to 256MB of
program memory. There are also parts of fsvm dedicated to doing math and bitwise logic, comparing and manipulating the stack. There is also 16777216
of accessible addresses than can either be RAM or some kind of I/O device.

## 3. Assembly for FurStack vm

### Assembly related syntax
#### rem
This defines the single line comment.

#### def [name] [value]
Defines a definition.

#### deflab [name]
Define a label.

### Instructions
#### noop
Do nothing. This is not used by FurStack compiler.

#### alu opcodes
They take top two stack values and preform operation on them. Top stack value to the right and next stack value to the left. There are 16 functions.

#### add
Addition.

#### sub
Subtraction.

#### mul
Multiplication.

#### umul
Unsigned multiplication.

#### fmul
Fixed-point multiplication.

#### div
Division.

#### udiv
Unsigned division.

#### fdiv
Fixed-point division.

#### mod
Modulo.

#### and
Bitwise and.

#### or
Bitwise or.

#### xor
Bitwise xor.

#### nor
Bitwise nor.

#### sll
Shift left logical.

#### srl
Shift right logical.

#### sra
Shift right arithmetic.

#### push [immediate/definition]
Push value into the stack.

#### stack opcodes
Those perform operations on stack. They don't take fixed size of stack values. There are 8 functions.

#### drop
Discard top stack value.

#### dup
Duplicate top stack value.

#### over
Duplicate next stack value.

#### tuck
Duplicate top stack value and put it below next stack value.

#### nip
Discard next stack value.

#### swap
Swap two top stack values.

#### rot
Move top third stack value to the top of the stack.

#### crot
Move top stack value below third stack value.

#### sw
Store top stack value to the address specified by next stack value.

#### lw
Load memory valua specified by the top stack value.

#### itp
Pop top stack value and push it to the iteration stack.

#### itc
Copy top iteration stack value to the stack.

#### itd
Pop top iteration stack value and push it to the stack.

#### Compare opcodes
They take two top stack value. Top stack value goes to the right and next stack value goes to the right. They push -1 if condition is true and 0 if not.
There are 10 functions.

#### eq
Equal.

#### ne
Not equal.

#### gt
Greater than.

#### ge
Greater than or equal to.

#### lt
Less than.

#### le
Less than or equal to.

#### ugt
Greater than unsigned.

#### uge
Greater than or equal to unsigned.

#### ult
Less than unsigned.

#### ule
Less than or equal to unsigned.

#### j [address/label]
Jump to specified address.

#### jc [address/label]
Jump to specified address if top stack value is not zero. Removes the top stack value.

#### jt [address/label]
Jump to specified address if top two values on iteration stack are equal. Drops them if they are equal.

#### cal [address/label]
Jump to specified address and save the return address on return stack.

#### ret
Jump to address specified on top of return stack. Return address is poped from return stack.

#### exit
Stop the execution of the program.

## 4. Additional stuff
Memory map:
0x000000-0x7fffff - Random Access Memory.
0x800000 - Terminal.
0x800001 - Clear Terminal.
0x800002 - Keyboard.
0x800003 - Time.
0x800004 - Random number.
0x800005-0xffffff - unused.
