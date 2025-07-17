# FurStack
FurStack is a stack-based programming language inspired by Forth, Basic and Java.

---

Content of this read me file:
1. Basic structure of the language
2. Keywords
3. Operands
4. Data types(are useless in there)
5. Other stuff
   
---

## 1. Basic structur of the language
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
And done, this is now a working FurStack program.
