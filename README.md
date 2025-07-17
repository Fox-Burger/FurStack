# FurStack
FurStack is a stack-based programming language inspired by Forth, Basic and Java.

---

Content of this read me file:
1. Basic structure of the language
2. Keywords
3. Operands
4. Data types(are useless in there)
5. Other stuff
6. FurStack Virtual Machine and it's assembly
   
---

## 1. Basic structure of the language
This language is stack-based. That means that it uses reverse polish notation(or rpn for short). You probably have seen this in your math class.
```
(2 + 3) * 5
```
That's how would we normally write math equations. In reverse polish notation, it looks like this.
``` forth
2 3 + 5 * .
```
Does it look weird? Yes. Does it make sense? Also yes. In reverse polish notation, operation you want to performe on numbers is after the numbers.
This is very fitting for stack. A stack is a memory structure, in which you can store the value on top of it(pushing) and load the value from the top (popping).
It's like the stack of plates. You can only the plate from the top or put a plate on the top, without breaking any plate.
This was used in some programming languages, like Forth. The example with rpn is actually a Forth program. FurStack works in similar way, but not really.
FurStack differs from Forth a lot. By a lot, I mean a lot. The program above would not in FurStack without some modifications.

#### Modification #1: main function
FurStack program in order to execute, needs main function. To declare function in FurStack, use the `fn` keyword. To end the function, put at the end `endfn` keyword.
```
fn main
	2 3 + 5 * .
endfn
```
#### Modification #2: remove the dot
In Forth, `.` prints the top stack value. FurStack doesn't have this so we remove it.
```
fn main
	2 3 + 5 *
endfn
```
And done, this is now a working FurStack program. This one doesn't print a result, but it will work.
Now we need to compile it with FurStack Compiler(fsc.lua). But after compiling it, you still can't run it. It needs to be assembled with FurStack Assembler(fsasm.lua).
Below is the usage of those.
```
./fsc.lua [FurStack program here] [the output file here]
./fsasm.lua [the compiled FurStack program here] [the output file here]
```
This is not very good to use and it will later change, but for now it works. Now you can run the program with FurStack Virtual Machine(fsvm.lua).
```
./fsvm.lua [program file here]
```
After doing that you should get nothing. We can try to see the result, but it will require more modifications.
#### Modification #3: varaible
We will add variable to out program. Variables can be defined with `let` keyword, followed by data type and name of variable. Like this.
```
fn main
	let int result
	2 3 + 5 *
endfn
```
We now have a variable of type integer named result. But to store the result of operation, we need more modifications.
#### Modification #4: storing
We can store the result of the calculation into our variable with `set` keyword. But to do it, we need to push another thing into the stack - out variable.
In FurStack, when you push a variable, you don't push it's value, you push it's pointer. Pointer point to location of variable in memory.
There are two ways to do it.
1) Push it after the calculation.
```
fn main
	let int result
	2 3 + 5 * result swap set
endfn
```
We push the pointer of the result variable on the stack. Then there comes the `swap`, which swaps the two top stack values. Then comes the `set` keyword.
2) Push it before the calculation.
```
fn main
	let int result
	result 2 3 + 5 * set
endfn
```
Writting program like this, gets rid of `swap` keyword. Now we can compile and assemble the program. We run it as before but add "--debug" at the end.
This will print the first 4096 memory slots after exiting the vm. If everything went well, you should see this in column starting with 0
```
0	25	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
```
And that's our result. There are probably better ways to do it, like making a function that does that, but I will leave that to you to figure out.

---

## 2. Keywords
FurStack has total of 25 keywords, 25 operators and 4 data types(more on them in chapter for of this file).
There are all of the keywords
| Keyword | Explanation | Example usage |
|---------|-------------|---------------|
| include | Include another FurStack program. | `include uwu.fu` |
| fn | Define function. | `fn main [code] endfn` |
| endrem | End function and return from it. | 'fn main [code] endfn` |
| deflab | Define label. | `deflab label` |
| rem | Start a comment. | `rem [comment] endrem` |
| endrem | End comment. | `rem [comment] endrem` |
| let | Declare variable. | `let int result` |
| const | Declare constant. | `const fixed pi 3.141` |
| array | Declare array. | `array char message 25` |
| set | Store value to given memory location. | `result 0 set` |
| fetch | Load value from given memory location. | `result fetch` |
| true | Push -1 to the stack. | `true` |
| false | Push 0 to the stack. | `false` |
| if | If condition is not 0, execute code after it, otherwise go to corresponding `else` keyword or `then` keyword. | `[condition] if [code] else [code] then` |
| else | Execute code after it, if condition failed. | `[condition] if [code] else [code] then` |
| then | End conditional statement. | `[condition] if [code] else [code] then` |
| while | Start a while loop. | `while [condition] do [code] endwhile` |
| do | If condition is not 0, execute the content of the loop, otherwise go pass corresponding `endwhile` keyword. | `while [condition] do [code] endwhile` |
| endwhile | Loop back to `while` keyword. | `while [condition] do [code] endwhile` |
| goto | Jump to label. | `goto label` |
| gofn | Jump to function. | `gofn main` |
| bye | End program. | `bye` |
| put | Write top stack value as ascii character. | `"A" put` |
| cls | Clear terminal. | `cls` |
| getin | Check for any input and put value of ascii character if any found, otherwise push 0. | `getin` |

---

## 3. Operators
As said above, there are 25 operators. Below they are listed.
| Operator | Explanation | Example |
|----------|-------------|---------|
| + | Add top two stack values. | `2 3 + rem result is 5 endrem` |
| - | Subtract top two stack values. | `2 3 - rem result is -1 endrem` |
| * | Multiply top two stack values. | `2 3 * rem result is 6 endrem` |
| fmul | Fixed-point multiplication on top two stack values. | `1.5 1.5 fmul rem result is 2.25 endrem` |
| / | Divide top two stack values. | `2 3 / rem result is 0 endrem` |
| fdiv | Fixed-point division on top two stack values. | `3.0 2.0 fdiv rem result is 1.5 endrem` |
| % | Modulo top two stack values. | `2 3 % rem result is 2 endrem` |
| & | Bitwise and on top two stack values. | `2 3 & rem result is 2 endrem` |
| [put vertical bar here] | Bitwise or on top two stack values. | `2 3 [put vertical bar here] rem result is 3 endrem` |
| ~ | Bitwise xor on top two stack values. | `2 3 ~ rem result is 1 endrem` |
| ! | Bitwise not on top two stack values. | `2 ! rem result is -3 endrem` |
| << | Logically shift to the left next value by top value. | `2 3 << rem result is 16 endrem` |
| >> | Arithmetically shift to the right next value by top value. | `-16 3 >> rem result is -2 endrem` |
| >>> | Logically shift to the right next value by top value. | `-16 15 >>> rem result is 1 endrem` |
| = | Check if top two stack values are equal. | `2 3 = rem result is 0 endrem` |
| ~= | Check if top two stack values aren't equal. | `2 3 ~= rem result is -1 endrem` |
| > | Check if next value is bigger than top value. | `2 3 > rem result is 0 endrem` |
| >= | Check if next value is bigger than or equal to top value. | `2 3 >= rem result is 0 endrem` |
| < | Check if next value is less than top value. | `2 3 < rem result is -1 endrem` |
| <= | Check if next value is less then or equal to top value. | `2 3 <= rem result is -1 endrem` |
| dup | Duplicate top stack value. | `1 2 3 dup rem now the stack is 1 2 3 3 endrem` |
| over | Duplicate next stack value. | `1 2 3 dup rem now the stack is 1 2 3 2 endrem` |
| swap | Swap top two stack values. | `2 3 dup rem now the stack is 1 3 2 endrem` |
| rot | Rotate top three stack values. | `2 3 dup rem now the stack is 2 3 1 endrem` |
| drop | Discard top stack value. | `2 3 dup rem now the stack is 1 2 endrem` |
Note: I haven't used actual vertical bar, because it's used in github's markdown for tables.

---

## 4. Data types
There are 4 data types:
| Datatype | Explanation |
|----------|-------------|
| int | Number between -32768 and 32767 |
| fixed | Fixed-point number between -128 and 127.996 |
| char | Ascii character. |
| bool | True or false. |

Notes:
1. Fixed point numbers are like floats, but decimal place is in the same spot.
2. Data types do nothing. You still can add character to a number. It's up to programmer to enforce it.
3. Yes, you can even store different values in variables with other data types. Even in bool.

---

## 5. Other stuff
Except for mentioned keywords, operators and data types, there are also other things.
1. Numbers
```
69 rem int endrem
3.141 rem float endrem
```
2. Strings
```
"Hello world!\n"
```
Escape sequences in FurStack are \ character followed by another character. The valid escape sequences in them are:
| ASCII code | Character |
|------------|-----------|
| 92 | \ |
| 34 | " |
| 39 | ' |
| 9 | tabulator |
| 10 | new line |

Small notes:
* Compiler, assembled and virtual machine interpret ASCII character 10 as new line, so if you use Windows or Mac, something will go wrong.
* Compiler does not care about the shape of the code. It can be shaped like donut or like windows logo or anything you like.
* Constants are not stored in memory of it's virtual machine. They are compiled to definitions.
* Yes, you can do weird stuff with the variable pointer.
* `bye` keyword is optional.
* There must be only one main function, either in your program, or the program to which is imported. The compiler will to complain, but the assembler will.
* The language is still work in progress, so some things might change.
* Assembled programs are in fact text files. The reason this is a thing, is because I wanted to use it with circuit simulator.
* If you wonder why the name is FurStack, just know it has something to do with furries.

---

## 6. FurStack Virtual Machine and it's assembly
As you probably noticed, compiler and assembler are separate. So if you don't value your sanity(or if you are a masochist), you can program vm in assembly.
The processor of vm is a stack-machine. It's architecture is centered around stack. In fact, processor of FurStack vm has two.
The first stack stores the data you will use to do calculations or do stuff with memory. The second one stores return addresses for the functions.
Both stacks have a fixed size of 4096 words(word being 16-bits). If you push to much, it will give error about stack overflow.
You can even cause stack underflow if the stack is empty and you attempt to do anything, for example math. Except for stacks, processor has 16 registers.
All of them are labeled from reg0 to reg15. They are connected to your primary stack. There is also 20-bit program counter which can access 1MB of program memory.
Note that not all instructions have equal width. Most take 1B, but some take 3B. There are also two very important parts of the processor of FurStack vm.
Those are the arithmetic logic unit(or alu for short) and compare unit. Compare unit compares numbers and pushes -1 if comparison is true and 0 if not.
The alu has 16 functions, while compare unit has 8. The other parts of virtual machine except the processor are program memory and main memory.
Program memory is just 1MB read only memory. The main memory is the funny part. It can either contain actual memory, or devices that are mapped to it.
For now, the virtual machine has 32KB of RAM, terminal and keyboard connected to it. Also, the processor can access up to 64KB of RAM. There is no memory mapping.
Below are the instructions of the virtual machine.
| Opcode number | Opcode mnemonic | Parameters | Takes more space | Notes |
|---------------|-----------------|------------|------------------|-------|
| 0 | noop | none | no | none |
| 1 | alu | alu function | no | For actual opcodes look into table with alu functions. |
| 2 | push | value | yes | none |
| 3 | drop | none | no | none |
| 4 | pur | register | no | none |
| 5 | por | register | no | none |
| 6 | sw | none | no | none |
| 7 | lw | none | no | none |
| 8 | dup | none | no | none |
| 9 | over | none | no | none |
| 10 | cmp | cmp function | no | For actual opcodes look into table with cmp functions. |
| 11 | j | address | yes | none |
| 12 | jc | address | yes | none |
| 13 | cal | address | yes | none |
| 14 | ret | none | no | none |
| 15 | exit | none | no | none |

alu function
| Function number | Mnemonic |
|-----------------|----------|
| 0 | add |
| 1 | sub |
| 2 | mul |
| 3 | mulu |
| 4 | div |
| 5 | divu |
| 6 | mod |
| 7 | fmul |
| 8 | fdiv |
| 9 | and |
| 10 | or |
| 11 | xor |
| 12 | nor |
| 13 | sll |
| 14 | srl |
| 15 | sra |

cmp functions
| Function number | Mnemonic |
|-----------------|----------|
| 0 | eq |
| 1 | ne |
| 2 | gt |
| 3 | ge |
| 4 | lt |
| 5 | le |
| 6 | gtu |
| 7 | ltu |
