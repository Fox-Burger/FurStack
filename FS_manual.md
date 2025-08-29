# FurStack manual
This file describes the basics of FurStack programming language

---

Content of the file:
1. Basics
2. Basic I/O
3. Variables and constants
4. Stack operations
5. Conditions
6. Loops
7. Comments
8. Arrays
9. Functions
10. Including other FurStack programs
11. List of all words and some other stuff

---

## 1. Basics
FurStack is a concatenative, stack-based programming language. This probably tells you nothing, so let me explain.
Concatenative programming language is a type of programming language, where everything is a function that operates on single piece of data. Combination of
functions express their composition. Functions or words as they are called, do not specify their arguments, making concatenative programming language
point-free. Most of those languages are very similar. Most of them use stack and reverse polish notation and FurStack is not an exception.
Stack is a type of memory working on principle of last in first out. When you put something on the stack, you push it. When you take something from the
stack, you pop it. It's like the stack of plates, where you can only put to or take from the top without breaking anything.
Reverse polish notation, or rpn is a way to write expressions. Most of you are probably familiar with infix notation. You had it in school in math class.
Below is an example of it.
```
(2 + 3) * 13
```
In infix notation, operator is between numbers. In rpn, operators are after the numbers. Below is example from Forth, the first concatenative programming
language.
```forth
2 3 + 13 * .
```
Order of operation goes from left to right and no parenthasies are required. This also perfectly replicates how stack operates.
If this what I said still doesn't make sense to you, your problem. But in nutshell, that's what FurStack is. It has a lot influence from Forth, just like
other concatenative programming languages. It's stack based and uses rpn. FurStack is a compiled language, meaning it requires to be compiled before being
executed. It consists from three main lua programs: fsc, fsm and fsvm.
fsc.lua is the FurStack compiler, it compiles to assembly for FurStack virtual machine.
fsm.lua is assembler for FurStack virtual machine.
fsvm.lua is the virtual machine that executes the code.

---

## 2. Basic I/O
Now lets write a simple FurStack program. The file extension if .fu and it is required, else compiler will complain. In the new file, lets write the first
program. Below is the code of the program, that prints the letter A.
```
fn main
	"A" put
	bye
endfn
```
First we have word fn. It defines function or word as it is called in languages like this. In FurStack, the program must have main word defined.
Then we have "A". It pushes letter A to the stack. After that, we have the word put. It pops the value from the stack and writes it as ascii character.
After that we have the word bye. It ends the program and is optional. The program will end when word main has ended it's execution.
At the end of program we have word endfn. It ends the function main. We can compile it with fsc.lua and then assemble the output file with fsm.lua
You can do it like this.
```
./fsc.lua -i [your FurStack program here].fu
./fsm.lua -i [your output file from compiler].s
```
Note that the compiler and assembler were designed to work on any unix-like operating systems that can run at least lua version 5.3 and nocurses module from
luarocks. With the program compiled and assembled, we can now run it using fsvm.lua
```
./fsvm.lua [your compiled and assembled program here].hex
```
And if you wrote everything as given above, you should see letter A printed to the terminal. The program we wrote uses I/O or input output.
FurStack has five instructions to interact with I/O of FurStack virtual machine. Those are: put, cls, getin, utime and rand.
Word cls clears the terminal. Below is the program to demonstrate it.
```
fn main
	"AB" put cls put
	bye
endfn
```
With the same way we pushed letter A, we can push more than one letter. Letters are pushed from right to left. That means that on top of the stack we have
the letter A and the letter B. We print A and the clear the terminal. After that we print the letter B and end the program.
Word getin check for any input. If there is any, it will push the ascii code of the character to the stack. If not, it will push zero. Keep in mind that
it will not halt execution and wait for the input. So if you write program like this.
```
fn main
	getin put
	bye
endfn
```
It will not wait for you to type anything, it will check for input, push zero because there is none and print that zero. Later we will try to make a word
to counter this problem.
Word utime gets the 24 bits of current time in seconds of unix time and pushes it into the stack.
Word rand pushes random number between 0 and 16777215 into the stack.
Those are all the words related to I/O of FurStack virtual machine. Now lets take a look at variables.
---

## 3. Variables and constants
Variables are a location in memory where we store a piece of data. The value of variable can be changed. In FurStack, you can declare variable using the
word let. Below is an example of declaring variable in FurStack.
```
fn main
	let var
	bye
endfn
```
To declare variable, you write word let and then the name of the variable. All variables by default are set to zero. To change the value of variable,
you can use word set. Below is example use of it.
```
fn main
	let var
	var 42 set
	bye
endfn
```
Word set takes two top stack values. Pointer to the variable and the value. When you push the variable, you don't push the value, but a pointer to it.
Another thing to keep in mind about variables is that there are no data types. FurStack, just like Forth, is untyped. Everything is treated as a number.
Yes, that means you can add a number to a character. Also, if you don't know what is a pointer, in nutshell it points to a memory location of variable.
If you want to read a value of a variable, you can use word fetch. It takes the pointer of the variable and pushes value at location specified by the pointer.
Below is the example program.
```
fn main
	let var1
	let var2
	var1 21 set
	var2 var1 fetch set
	bye
endfn
```
There, we declare two variables. Then, we set var1 to 21. After that, we set var2 to value of var1. Now that we have talked about variables, now lets talk
about constants. Constant is a value that will not change during the execution of the program. They often aren't stored in the memory. To declare constant
in FurStack, you use the const keyword. Below is example of declaring constant.
```
fn main
	const pi 3.141
	let var
	var pi set
	bye
endfn
```
After word const, you write the name of the constant and it's value. Values can be a integer, decimal, charcter or boolean. Boolean has only two values,
true or false. FurStack interprets zero as false and everything else as true. There are even words true and false. Word true pushes negative one and word
false pushes zero. Now back to example program. We declare constant pi and variable var. We set variable var to value of pi. Constants don't require use of
word fetch, they push their value when called. That's all there is to it. There are also arrays, but we will talk about them later. Time for more
interesting stuff.

---

## 4. Stack operations
Every programming language needs to be able to do math. FurStack can do math and this is one of the topics of this section. Let's talk about them.
FurStack can do addition, subtraction, multiplication, division and modulo. Lets start simple with addition.
```
fn main
	2 3 +
	bye
endfn
```
This program will push 2 and 3 into the stack and add them together. The order of numbers doesn't matter, because it's addition. But it does in subtraction.
```
fn main
	8 3 -
	bye
endfn
```
We push 8 and 3 into the stack. Then we subtract 3 from 8 and get 5. In FurStack top stack value goes to the right and value below goes to the left.
Keep that in mind when programming. Multiplication and division are also possible in FurStack.
```
fn main
	4 8 * 2 /
	bye
endfn
```
Another thing about multiplication and division is that there are three versions of each. `*` and / perform math on signed numbers. Those numbers can be
negative. Then there are `u*` and u/ which do the same, but on unsigned numbers. Unsigned numbers are always positive. And finally, fmul and fdiv for
doing those operations on fixed point numbers.
```
fn main
	2.5 3.0 fmul
	bye
endfn
```
While we at those, let's talk about fixed point numbers. There are two ways to represent decimals in computing: floating point and fixed point.
FurStack uses fixed point, where decimal point stays in the same spot, no matter what. FurStack uses 24-bit numbers and fixed point numbers use
first 12-bits for whole part and last 12-bits for decimal part. Then there is modulo which returns the remainder of division.
```
fn main
	5 2 %
	bye
endfn
```
That were all the arithetic operations. There are more. Now let's talk about bitwise logic operations. Those are and, or, not and xor.
```
fn main
	8 5 &
	8 5 |
	8 5 ~
	8 !
	bye
endfn
```
Bitwise and is represented by &, or by |, xor by ~ and not by !. And sets bit to 1 if both bits are 1. Or sets bit to 1 if any of the bits is 1. Xor
sets bit to 1 if only one bit is 1. Not inverts the bit, so 0 will become 1 and 1 will become 0. Note that not takes only one number, not two.
Then there are bit shift operations. Bit shifting is like multiplying number by power of two, but it's faster than multiplication and division.
```
fn main
	3 2 <<
	2 >>>
	-1 * 1 >>
	bye
endfn
```
<< shifts the value to the left, multiplying it. For shifting to the right, basically dividing it, there are two operations. >>> shifts the bits asuming the
number is positive. >> does the same, but account for sign. Then there are operations for comparing the numbers. Those take two numbers and compare them.
```
fn main
	2 2 =
	2 3 ~=
	3 2 >
	3 3 >=
	2 3 <
	3 3 <=
	bye
endfn
```
= checks if numbers are equal. ~= checks if numbers are not equal. > checks if next stack value is greater than top stack value. >= checks if next stack
value is greater than or equal to top stack value. < checks if next stack value is less than top stack value. <= checks if next stack value is less than
or equal to top stack value. >, >=, < and <= have unsigned version as well. Now time for operations related to stack. Some move data on stack around, some
duplicate a value and some remove a value. The words that duplicate are: dup, over and tuck. Dup duplicates the top stack value. Over duplicates the value
below top stack value. Tuck also duplicates top stack value, but it puts it below next stack value.
Words that move data around are: swap, rot and crot. Swap swaps two top stack values. Rot rotates top three stack values. To explain it better, I will
show example program.
```
fn main
	"ABC" rot put put put
	bye
endfn
```
This should output CAB. Crot does the same thing as rot, but in other direction. So if you write rot crot, it will cancel out the effects of rot.
Words for deleting the data from stack are drop and nip. Drop discards top stack value. Nip discards next stack value. Now there are only three words left
to explain, but before that, lets talk a bit about Forth and architecture of FurStack virtual machine.
In Forth, you can access return stack. You can move values between those stack and copy values from return stack. This allows for many things. In FurStack,
return stack is inaccessable. Because of it, FurStack has one more stack named the iteration stack. It's main use is for loop about which we will talk later.
You can manipulate this stack with three words: >i, i@ and i>. Below is the program uses iteration stack to duplicate value.
```
fn main
	69 >i i@ i>
	bye
endfn
```
>i pops top stack value and pushes it to iteration stack. i@ copies the top value of iteration stack. i> pop top value from iteration stack and pushes it to
the stack. That's all the operations in this chapter. It's quite long. Now let's talk about other things.

---

## 5. Conditions
Program sometimes needs to be able to execute code if the condition is met. That's why conditional statements exists. Conditional statements execute piece
of code if condition is true or execute another if condition is false. In FurStack, to create it, you use if word. Below is the example code to show the
conditional statement.
```
fn main
	5
	5 = if
		"T" put
	then
	bye
endfn
```
We push 5 into the stack. Then we push 5 and check if the value is equal to it. If the condition was true, it will print the letter T. Conditional statement
in FurStack end with word then. If you want to write something else if condition was false, you can use word else. Below if slightly modified program from
above.
```
fn main
	4
	5 = If
		"T"
	else
		"F"
	then
	put
	bye
endfn
```
It does the same as before, but when condition is false, it will print letter F. The if statements can be put inside another if statement. Below is the
program that checks if the value of variable is greater than, less than or equal to zero.
```
fn main
	let var
	var 69 set
	var fetch 0 > if
		"G"
	else
		var fetch 0 < if
			"L"
		else
			"Z"
		then
	then
	put
	end
endfn
```
First, we declare variable var and set it to 69. Then we check if it is greater than zero. If it is, it will push letter "G" into the stack. If not, it
will check if it is less than zero. If it is, we push letter "L". Otherwise we push letter "Z". At the end, we print the top stack value and exit.
That's all there is to it. Not hard to understand.

---

## 6. Loops
Sometimes we need to execute a piece of code many times. Writting it by hand is a bad idea, so loops exists. In FurStack, there are three kinds of loops:
while loop, repeat until loop and for loop. Lets start with while loops. While loop will be looping while the condition is true. Below is example program
that prints numbers from 0 to 9 using while loop. While loop ends with word endwhile.
```
fn main
	let i
	while i fetch 10 < do
		"0" i fetch + put "\n" put
		i dup fetch 1 + set
	endwhile
	bye
endfn
```
First, we declare variable i. We don't change it's value, because by default variables are set to 0. Then we start the while loop. Condition of while
loops is located between words while and do. If condition is true, it will execute code inside the loop. It will push character "0". It's ascii code is 48.
Then it will add value of variable i and write it. Then we write the new line character. We will talk about it more in section about arrays. Before we go
back to condition of the loop, we increment value in variable i. This will repeat until the value in variable i is not less than 10. While loops are good
when you don't know how many times will the code execute. Now lets talk about repeat until loop. Repeat until loop works like while loop, but with a catch.
Condition is at the end. Below is the program above written with repeat until loop.
```
fn main
	let i
	repeat
		"0" i fetch + put "\n" put
		i dup fetch 1 + set
	i fetch 10 < until
	bye
endfn
```
We declare variable i. Then we enter the repeat until loop. We execute code inside and come to condition. If condition is true, it will loop, otherwise it
will exit the loop. Repeat until loop is good for cases, where code must execute at least once. And finally, the for loop. For loop uses iteration stack.
For loop uses words loop and for. Below is the previous program written with for loop.
```
fn main
	0 10 loop
		"0" i@ + put "\n" put
	for
	bye
endfn
```
This time we don't declare variable. We could write the previous programs to not use variables, but we already did so whatever. We specify the start index
and amount of iterations. In this case, start index is 0 and it will loop for 10 times. Then we have the word loop, which starts the for loop. Inside the
loop, we copy top stack value from iteration stack and add it to character "0". We don't need to increment it, word for does that for us. It will always
increment the loop index by 1. For loops are perfect for cases where we know how many times we want to loop. Before we get to next section, lets finally
write the hello world program. Here it is.
```
fn main
	"Hello world!\n\0"
	while dup 0 ~= do
		put
	endwhile
	drop
	bye
endfn
```
First, we push "Hello world!\n\0". There you can see the escape sequences. These allow you to insert some characters inside it. \n pushes the new line,
which has the ascii code of 10. Another one is \0, which pushes 0. It will be needed. Other escape sequences are \b for backspace, \t for tabulator, \r
for carriage return, which is also a new line character on MacOS, \e for ansi escape sequence, \\ for slash, \" for double quotes and \' for single
quote. Then we have the while loop. We duplicate top stack value and check if it is not zero. If it isn't zero, it will print it. Otherwise it will drop
that zero and exit. Another thing I will mention is that you probably noticed that with more values on the stack it's harder to access lower values.
Lets consider a program where you have nested loops. Yes, you can nest loops.
```
fn main
	1 10 loop
		1 10 loop
			i> i> i@ crot >i >i i@ *
			put
		for
		"\n" put
	for
	bye
endfn
```
To access the value of previous loop, we needed to temporary push the iterator and final number to our main stack, copy the iterator of previous loop,
rotate elements on the stack, put back loop related values and copy the iterator of current loop. That's way harder, isn't it. Now, lets go to next section.

---

## 7. Comments
Sometimes it's better to write down what the function does or what it will do with the stack. That's why we need comments. Comments in FurStack can be
written between words rem and endrem. rem is multiline comment. At the moment there are no single line comments. There is not a lot to talk about so
we will just get to next section.

---

## 8. Arrays
There are cases where we want to store some data together. Creating multiple variables is stupid, so smart people have come up with arrays. Array is
not a one memory slot, but several. In FurStack, you can define array almost the same way as constants. Below is example program with array.
```
fn main
	array vars 5
	0 5 loop
		vars i@ + i@ 1 + set
	for
	bye
endfn
```
We declare arrays with word array. We give it a name and amount of cells it will have. Then we have a for loops which stores values from 1 to 5 in our
array. Pointers can be altered, which allows for accessing other values of array. The first address of our array is pointer of vars. The second is
vars + 1 and so on. We can use arrays to store many things in it or even to recreate strings. After all, string are just arrays of characters.
Below is example program demonstrating it.
```
fn main
	array string 7
	"Hello!\0" string
	while over 0 ~= do
		dup rot set
		1 +
	endwhile
	bye
endfn
```
We declare an array with lenght of 7. Then we push string and pointer to array. Then we have a while loop. Inside it, we duplicate the pointer and rotate
the top three stack values. We store the character to array and increment the pointer by 1. We repeat this until we encounter zero. There are no operations
to get the lenght of the array or to manipulate them. You need to make this yourself. Now lets get to another topic.

---

## 9. Functions
Lets say we have a code that needs to be in ten places inside a program. Copying and pasting it ten times would be a bad idea, so we have functions.
Function is a piece of code that can be called from anywhere in the program. In concatenative programming languages they are refered as words, because
you don't specify the arguments. Concatenative programming languages use point-free programming, meaning that functions don't specify the arguments and
don't care how they get the arguments. This can also be interpreted as function taking stack as argument and returning another stack. You can put functions
inside another function, creating a composition. You have seen a function already, it's the main function. With the same words you can define functions.
Let's create a getchar function.
```
fn getchar
	0
	repeat
		drop getin
	dup 0 = until
endfn

fn main
	getchar put
	bye
endfn
```
We declare getchar function the same way we declare main function. Inside we push 0. After that, we encounter a repeat until loop. We drop that zero and
check for any input. If it is zero, it will continue. It it isn't, it will exit the loop, leaving the character we inputed on the stack. In the main function
we call getchar and print the inputed character. Another thing related to functions is recursion. Recursion means that we are calling function from inside
of itself. To demonstrate it, let's write a program from section 6 using recursion.
```
fn recursive
	dup 0 = if
		"0\n" put put drop
	else
		dup 1 - recursive "0" + put "\n" put
	then
endfn

fn main
	9 recursive
	bye
endfn
```
This program is possible thanks to return stack, which stores the return addresses every time function is called. In main function we push 9 and call out
function. Our recursive function will check if the number is zero. If it is, it will print it. If not, it will recurse and then print the value.
That's all in this section. Time to see another one.

---

## 10. Including other FurStack programs
Writting everything in one file is not the best thing to do. It's sometimes a good idea to split program into multiple files. We can include these files
with include word. To explain it, let's asume we have two files, our main program and program with function to print text.

main.fu
```
include lib.fu

fn main
	"Hello world!\n\0" write
	bye
endfn
```
lib.fu
```
fn write
	while dup 0 ~= do
		put
	endwhile
	drop
endfn
```
In lib.fu, we have function write. It prints characters until it encounters zero. In main.fu we include lib.fu. In main function we push string
"Hello world!\n\0" and call write function from lib.fu. Note that in the file you include, you should not write the main function. Otherwise the compiler
will complain. Another thing to note is that FurStack uses static linking, meaning it will include everything from included file inside, including functions
you will not use. This is a waste of space, but this was easy to implement. With that in mind, this is all about FurStack. I hope you learned enough.

---

## 11. List of all words and some other stuff
Words:
1. include
2. fn
3. endfn
4. rem
5. endrem
6. let
7. const
8. array
9. set
10. fetch
11. true
12. false
13. if
14. else
15. then
16. while
17. do
18. endwhile
19. repeat
20. until
21. loop
22. for
23. bye
24. put
25. cls
26. getin
27. utime
28. rand
29. +
30. -
31. *
32. u*
34. fmul
35. /
36. u/
37. fdiv
38. %
39. &
40. |
41. ~
42. !
43. <<
44. >>
45. >>>
46. =
47. ~=
48. >
49. >=
50. <
51. <=
52. u>
53. u>=
54. u<
55. u<=
56. dup
57. over
58. swap
59. rot
60. drop
61. tuck
62. nip
63. crot
64. >i
65. i@
66. i>

Escape codes:
1. \t - tabulator
2. \n - new line
3. `\\` - backwards slash
4. \' - quote
5. \" - double quote
6. \b - backspace
7. \r - carriage return
8. \e - escape sequence
9. \0 - null character
