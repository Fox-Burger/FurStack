# FurStack manual
This file describes the basics of FurStack programming language

---

Content of the file:
1. Basic structure
2. Basic I/O
3. Variables and constants
4. Stack operations
5. Conditions
6. Loops
7. Comments
8. Arrays
9. Functions
10. Including other FurStack programs
11. List of all keywords, operands, data types and some other stuff

---

## 1. Basic structure
FurStack is a concatinative programming language. You probably have no idea what it means so let me quickly explain.
Concatenative programming language is a type of programming language in which everything is a function.
They use compositions which are combinations of functions. The functions don't specify their arguments. Concatenative programming language operate on one piece of data.
In most of them it's stack. Also, in most of them syntax is based on reverse polish notation. FurStack is no exception and it also uses stack and reverse polish notation.
But you probably have no idea what it means so let me quickly explain. Stack is a piece of data, in which data is put at the top and taken from the top.
It's like a stack of plates. You can take plate from the top and take a plate from the top. If you will try to take a plate from the middle, you will break some plates.
Reverse polish notation (or RPN for short) also known as postfix notation is one of the ways expressions are written. Operators are after the arguments.
This is very good for stack based languages, because it closely resembles how they work. If you don't get it, let me show you an example.
```
(2 + 3) * 5
```
You probably have seen calculations written like this. In rpn, it's written differently. Below it's the same thing but written in Forth.
```forth
2 3 + 5 *
```
This is the same thing as the first example, but written in rpn. FurStack works in similar way. FurStack is a language that was inspired mainly by Forth, Basic and Java.
Forth was the first concatinative programming language. FurStack borrows a lot from it.
Basic was a interpreted programming language that was popular in times of 8-bit computers. It was simple and that's what FurStack (badly) tries to implement.
Java is a compiled programming language that doesn't compile to architecture of any regular computer, but it compiles to bytecode for it's stack based virtual machine.
FurStack also uses stack based virtual machine. (Other concatinative programming languages also use stack based vm, but for FurStack Java was the inspiration)

---

## 2. Basic I/O
We will start by learing about I/O instructions of FurStack. Those instructions are named keywords. Keywords are words reserved for a compiler or interpreter.
FurStack has three I/O keywords. Those are put, cls and getin. put gets top stack value and outputs it as ASCII character to the terminal. cls clears the terminal.
getin checks if there is any input from the user. If there is any, it puts the ASCII value of the character to the stack. Otherwise it puts zero.
There I will introduce two terms. Push and pop. Pushing means that we put a value on top of the stack. Popping means that we remove the top value from the stack.
Now let's write a program that prints letter A to the terminal. We start by defining the main function. FurStack program needs main function. Without it, it will not work.
We will talk about functions more in section 9, but for now know that they start with fn keyword and end with endfn keyword. Inside the function put "A".
Anything between double quotes will be interpreted as pushing many values. FurStack has no strings, so this will be converted to pushing numbers with the corresponding ASCII value.
then we write put keyword. If you want, you can also write bye keyword. It stops the program. It's optional, because after the main function, the program will end.
If you followed what I said, the program should like this.
```
fn main
	"A" put
	bye
endfn
```
Note that this shape of the program doesn't matter. The program can be shaped like a donut and it will still execute. But now let's compile it.
To compile it, we need to use FurStack Compiler (fsc.lua). To compile the program, write this.
```
./fsc.lua -i [your program]
```
Note that the program must end with .fu or it will not compile. If you want to specify the output file, add -o parameter. Note that the output file must end with .s
This will be needed, because fsc doesn't compile to ready to execute program. We need to assemble it. To do it, we need FurStack Assembled (fsasm.lua)
The usage of assembler is the same as fsc.lua but you need to give it file ending with .s and any optional output file must end with .hex
```
./fsasm.lua -i [your program]
```
Now that we have compiled program, we can run it with FurStack Virtual Machine (fsvm.lua). Just type the name of your program and it should work.
```
./fsvm.lua [your program]
```
If you did everything right, it should display letter "A". If it didn't work, you either typed something wrong or you use Windows or MacOS. FurStack for now works with linux only.
Now let's write a program with cls keyword. You can make new program or modify the previous program.
```
fn main
	"AB" put cls put
	bye
endfn
```
You probably have no idea what it does so let me explain. First, we push two letters to the stack. On top is letter "A" and below it is letter "B". Then we write top stack value.
After that we clear the terminal and write top stack value. You should see the letter "B". This also demonstrates how characters are pushed. Letter "B" was pushed first.
After that, "A" was pushed. I will not make the program with getin keyword, I will leave that for other section.

---

## 3. Variables and constants
Variables is a place in memory, where we store out value. We can modify the value of variable. Constant is something similar, but you can't change it's value.
In FurStack, the keyword let is used to define variable. The other thing we need to keep in mind it the data types. They tell the programmer what is stored there.
The data types in FurStack are:
1. int - integer. Number between -32768 and 32767
2. fixed - Fixed-point number. Fixed-point number are like floating-point numbers but not really. The decimal point stays in place, while in float it moves.
It can represent the numbers between -128 and 127.996
3. char - Character. It can be any character that fits in 16-bit (more on that a bit later).
4. bool - Boolean. It's either true or false.
These data types are limited by bit size of FurStack vm, which is 16-bit. Below is the example program with variable.
```
fn main
	let int myVar
	bye
endfn
```
This program defines variable. First you write let followed by data type, the you write the name. It's not very interesting. Now lets learn how to interact with the variables.
You probably think that you can use variable name to get it's value, but no. When you write variable name, it will push a pointer to that variable.
Pointer is a number that point to the address of variable in memory. To get the value of the variable, you need fetch keyword. To store value to a variable, you need set keyword.
Below is the program that explains it.
```
fn main
	let char myVar
	myVar "A" set
	myVar fetch put
	bye
endfn
```
First, we define variable myVar with char data type. Then we push pointer to myVar and "A" char. Keyword set takes two top stack values. Top value is the value we store.
Value below is out pointer. In line below, we push pointer to myVar and the fetch it. After fetching it, we print it to the terminal. And finally, we end the program.
This should print "A" to the terminal. Now let me show you another thing about FurStack.
```
fn main
	let int myNum
	let char myChar
	myNum 48 set
	myChar myNum fetch set
	myChar fetch put
	bye
endfn
```
After looking at it, you will think it will not work, but no. It will write character "0". This works for one reason. FurStack is in fact, untyped.
Compiler doesn't care about types. Programmer needs to enforce it himself. The only reasons data types exist in FurStack are:
1. Making programmers life easier.
2. Constants use it for figuring out what the value is.
Now lets talk about constants. They are definded with const keyword. They are defined almost like variables, but take one more parameter, the value.
Unlike variables, constants aren't stored in memory. Compiler compiles them to definitions. Because of this, you don't need set and fetch keywords when using constants.
This also makes sure that you can't override their value. Below it the example program with constant
```
fn main
	const char letterA "A"
	letterA put
	bye
endfn
```
The program will write the letter "A" to the terminal. Now lets talk for a bit about booleans. They can be either true or false. FurStack has true and false keywords.
keyword true pushes -1 to the stack and keyword false pushes 0 to the stack. Keyword true could be anything. For FurStack, 0 is false and everything else is true. Another thing I will mention shortly is utime keyword. It pushes the time since midnight 01.01.1970 in seconds. Note that it's only the last 16-bits.

---

## 4. Stack operations
Computers are good at math (or at least when it comes to integers. More on that later). FurStack has 25 stack operations. Let's start with math operations.
Let's asume we have a FurStack program that has pushed 2 and 3 to the stack. Now let's see how different operations affect the stack.
The `+` symbol does the addition. With this, we add 3 to 2 and we get 5. To subtract, we use `-` symbol. With this, we subtract 3 from 2 and get -1.
This might make no sense to you, but lets look at how we would write it in infix notation
```
2 - 3
```
After looking at it, it might make sense now. Top stack value goes to the right and next value goes to the left. After this we perform the operation.
Other operators are `*` for multiplication, `/` for division and `%` for modulo. Modulo gets the remainder of the division.
Note that `*`, `/` and `%` do integer division only, so for fixed-point numbers, it will not work. We will talk about it later.
Now lets talk about logical operations. We will use the same values as above. Lets start with bitwise operations. Those perform operations on the bits.
If you have no idea what binary system is or what logic gates are, go watch any video about them and then come back. If you know what those are, you can continue.
`&` does bitwise and. It will take the values and push 2. `|` does bitwise or. It will return 3. `~` does bitwise xor. It will return 1. And finally, `!` does bitwise not.
It will only take top stack value and will invert it's bits. It will take 3 and return -4. Other types of bitwise operations are bit shifts.
FurStack has three bit shifting operations. Bit shifting shifts the number in specific direction by specified ammount.
`<<` does logical shift to the left. It will shift 2 by 3 and return 16. This is equal to multiplying 2 by 8. There are also two bit shifting operations, that shift to the right.
`>>>` does logical shift to the left. If you do that with 16 and 3, you will get 2. `>>` does the arithmetic shift to the right. Preserves the sign of the number.
Doing `-2 1 >>` will give -1 and doing `-2 1 >>>` will give 32767. Keep that in mind.
Now let's talk about doing multiplication and division with fixed-point numbers. Operators for this are `fmul` for multiplication and `fdiv` for division.
Module for fixed-point numbers is useless. You can convert int to fixed-point number for FurStack by shifting number to the left by 8.
Doing arithmetic bit shift to the right will convert fixed-point to int. Below is the example program with `fmul` and `fdiv`
```
fn main
	1.5 dup dup fmul swap fdiv
	bye
endfn
```
This program will multiply 1.5 by 1.5, which will output 2.25 and then divide it by 1.5, which will output 1.5
You have probably noticed other operations there. FurStack has some of the most basic stack operations. And yes, they were taken from Forth.
I will show how they work on stack that has three values. 1, 2 and 3. The operations are:
1. dup - Duplicate the to stack value. {1, 2, 3, 3}
2. over - Duplicate the stack value below. {1, 2, 3, 2}
3. swap - Swap the top two stack values. {1, 3, 2}
4. rot - Rotate the top three stack values. {2, 3, 1}
5. drop - discard the top stack value. {1, 2}
And before we go to next section, lets talk about comparing numbers. Lets asume we have 8 and 5 on the stack. If comparison is true, it will push -1. Otherwise it will push 0
`=` will check if top two stack values are equal. 8 and 5 aren't equal so it will push 0
`~=` will check if top two stack values are not equal. 8 and 5 aren't equal so it will push -1
`>` will check if next stack value is greater than top stack value. 8 is greater than 5 so it will push -1
`>=` will check if next stack value is greater that or equal to top stack value. 8 is greater than 5 but not equal to it so it will push -1
`<` will check if next stack value is less than top stack value. 8 is not less than 5 so it will push 0
`<=` will check if next stack value is less that or equal to top stack value. 8 is not less than 5 nor equal to it so it will push 0
Those are all stack operations in FurStack.

---

## 5. Conditions
Every programming needs to be able to do conditional statements. FurStack also has conditional statement. It's if statement. Below is the example program with it.
```
fn main
	8 5 > if
		"T" put
	else
		"F" put
	then
	bye
endfn
```
First, we write the condition. The we have the if keyword. If the top stack value is not zero, it will execute the code between if and else or then keywords.
Otherwise it will go to else or then. In this case, if the condition is true, it will print the "T" character.
Keyword else is optional, it executes code between itself and then keyword, if condition failed. Then keyword ends the conditional statement.
You can put more conditionals inside if statement. Compiler will handle it. To show it, lets write a program that checks if the number is positive, negative or zero.
```
fn main
	let int num
	num 69 set
	num fetch 0 > if
		"P" put
	else
		num fetch 0 < if
			"N" put
		else
			"Z" put
		then
	then
	bye
endfn
```
We declare variable num and store number into it. Then we check if it is greater than zero. If it is, it will print "P". Otherwise it will move to next if statement.
It will check if the number is less than zero. If it is, it will print "N". Otherwise it will print "Z".

---

## 6. Loops
Writting the same code all over again can be annoying. Sometimes we don't know how many times it needs to execute. Because of it, we need loops. FurStack has two loops.
Those are while loop and repeat until loop. While loop will loop only if the condition is true. Lets write an example program that writes letter from "A" to "J".
```
fn main
	let int i
	i 0 set
	while i fetch 10 < do
		"A" i fetch + put
		i dup fetch 1 + set
	endwhile
	bye
endfn
```
First, we declare variable i and set it to 0. Then we start the while loop. We put condition between while and do keywords. In this case, is variable i less then 10.
Do keyword will go to endwhile keyword, if condition is false. Otherwise it will execute code inside the loop. Keyword endwhile ends the loop.
Inside the loop, we add current value of variable i to character "A" and print it out. Before we loop back to while keyword, we increment variable i by 1.
Another loop in FurStack is repeat until. It's almost like while loop, but it will always execute at least once, due to condition being at the end of the loop.
Below is the previous program, but with the repeat until loop.
```
fn main
	let int i
	i 0 set
	repeat
		"A" i fetch + put
		i dup fetch 1 + set
	i fetch 10 < until
endfn
```
Instead of while, we use repeat. Condition has been moved to the end, right before the until keyword. Keyword until works kinda similar to do keyword.
As long as the condition is true, the loop will repeat. Repeat until loop is useful when you know the loop will execute at least once.

---

## 7. Comments
Comments are useful to describe what the part of the code does. Especially when you come back to your project after a long break.
In FurStack, comments are between rem and endrem keywords. This is a multiline comment, meaning it can take more than one line.
Below is the program from the previous section, but with comments.
```
fn main
	rem i will be out iterator endrem
	let int i
	i 0 set
	rem check if i is less than 10 endrem
	while i fetch 10 < do
		rem add value of i to A and print int
		then increment i by 1 endrem
		"A" i fetch + put
		i dup fetch 1 + set
	endwhile
	rem exit endrem
	bye
endfn
```
Comments also allow you to comment out part of the code.

---

## 8. Arrays
Sometimes you want to store some data together. Making a lot of variables is not the best idea, so some smart people created arrays.
Array is like taking multiple variables and combining them into one. Data in array can be accessed by index of that data. You can declare a variable in FurStack with array keyword.
You define it almost like a constant, but the last value must always be a integer. It will be the lenght of array. Below we create a simple program with array.
```
fn main
	let int i
	array char message 4
	i 4 set
	0 "Hi!"
	while i fetch 0 > do
		message 4 i fetch - + swap set
		i dup fetch 1 - set
	endwhile
	bye
endfn
```
We declare variable i and array message of type char. Then we set i to 4 and push "Hi!" to the stack. We also push zero, because why not. Then we start a while loop.
While i is greater than zero. We can access different indexes of an array by adding index to pointer of the array. It's not very memory safe, but code runs in vm so whatever.
In this case, we subtract value of i from 4 and add the result to the pointer. Then we store the character that we already pushed on the stack.
And before we loop back we increment i by 1. Arrays in FurStack are one dimentional. Due to lack of string data type, we can emulate it using arrays, because that's what string are.

---

## 9. Functions
Functions allow you to write a code that can be called from anywhere in the program. They are very important in functional and concatinative programming.
You already know how to declare a function. If you forget, the let me remind you. Keyword fn defines it and endfn ends the function. Function can be called by their name.
Functions can be called from the inside of them self. This is called recursion. Functions in concatinative programming languages are equal to compositions of functions inside it.
Concatenative programming languages are point-free, meaning that functions don't directly specify their parameters. The data they operate on is on the stack.
It can be also interpreted as function taking stack as parameter and returning new stack as a result. Following this, everything is a function.
Below is example function, getchar.
```
fn getchar
	true
	while do
		getin
		dup 0 = if
			drop true
		else
			false
		then
	endwhile
endfn
```
We first push true. Then we have a loop. As you can see, there is no condition. In this case, we don't need it. Then we have getin keyword.
I said in section 2 that we will get back to it. Now we do it. Because getin check for any input now, it might not get user input. Because of it, we put it in the loop.
If it doesn't get user input, it drops the zero and pushes true, so the loop can continue. Otherwise it will end the loop.

---

## 10. Including other FurStack programs
Writting everything in one file is not a good idea, so you can split your program into multiple files. In FurStack, you can do it with include keyword.
Let's say that we have a file named stdlib.fu that has functions write, writeNum and getchar. To use function write to print a message, we can do this.
```
include stdlib.fu

fn main
	0 "Hello world!" write
	bye
endfn
```
We write the include keyword followed by name of the file. Include will copy and paste the content of the specified file inside our file. Then we have the main function.
Inside it, we push zero and our message. Then we call write function from the stdlib.fu file. After the function returns, the program ends.

---

## 11. List of all keywords, operands, data types and some other stuff
Keywords:
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
21. bye
22. put
23. cls
24. getin
25. utime

Operators:
1. `+`
2. `-`
3. `*`
4. `/`
5. `%`
6. `fmul`
7. `fdiv`
8. `&`
9. `|`
10. `~`
11. `!`
12. `<<`
13. `>>`
14. `>>>`
15. `=`
16. `~=`
17. `>`
18. `>=`
19. `<`
20. `<=`
21. dup
22. over
23. swap
24. rot
25. drop

Data types:
1. int
2. fixed
3. char
4. bool

Escape codes:
1. \t - tabulator
2. \n - new line
3. `\\` - backwards slash
4. \' - quote
5. \" - double quote

notes:
1. The compile, assemble and virtual machine interpret ASCII code 10 as new line. This will cause problems for Windows and MacOS users.
2. As I said, you can manipulate variable pointer. As you can guess, you can screew yourself if you not careful.
3. The must always be one main function. Otherwise compiler or assembler will complain.
4. Language design is not final. Things might change, but the language will remain concatenative.
5. If you wonder about the name of the language, just know it has something to do with furries.
