# Project : Regular Expression Interpreter
CMSC 330, Fall 2017  
Due October <s>23rd</s> 26th, 2017 at 11:59 PM

Library functions to use include [`Pervasives` module][pervasives doc], as well as functions from the [`List`][list doc] and [`String`][string doc] modules. 

Introduction
------------
The goal of this project is to implement the `Nfa` and `Regexp` modules, which implement NFAs and a regular expressions interpreter, respectively. The signature and starter implementation for the two modules is provided. Please take a look at the interface files (`nfa.mli` and `regexp.mli`).

Project Files
-------------
The following are the relevant files:

* OCaml Files
  * __nfa.ml__ and __nfa.mli__: This will contain the first part of the project, the NFA implementation.
    * Note that you will not change `nfa.mli`!
  * __regexp.ml__ and __regexp.mli__: This will contain the second part of the project, the regular expressions interpreter. It also contains an implementation of a parser where I can use some of the funtions such as `string_to_regexp` and `string_to_nfa` for creating your own test cases.
    * Note that you will not change `regexp.mli`!
  * __public.ml__: This file contains all of the public test cases.
  * __viz.ml__: This script can be used to display regex NFAs. This is a very useful debugging tool! Described more below.
  

Part 1: NFA Implementation
--------------------------

### Functions to implement

**make_nfa ss fs ts**

* **Type:** `int -> int list -> transition list -> nfa_t`
* **Description:** This function takes as input the starting state, a list of final states, and a list of transitions, returing an NFA. 
* **Examples:**
```
let m = make_nfa 0 [2] [(0, Some 'a', 1); (1, None, 2)] (* returns value of type nfa_t *)
let n = make_nfa 0 [2] [(0, Some 'a', 1); (1, Some 'b', 0);(1,Some 'c',2)] (* returns value of type nfa_t *)
```

**get_start m**

* **Type:** `nfa_t -> int`
* **Description:** This function takes as input an NFA and returns the state number of the start state.
* **Examples:**
```
get_start m = 0 (* where m is the nfa created above *)
```

**get_finals m**

* **Type:** `nfa_t -> int list`
* **Description:** This function takes as input an NFA and returns the state numbers of all final states.
* **Examples:**
```
get_finals m = [2] (* where m is the nfa created above *)
```

**get_transitions m**

* **Type:** `nfa_t -> transition list`
* **Description:** This function takes as input an NFA and returns the list of all transitions in the NFA.
* **Examples:**
```
get_transitions m = [(0, Some 'a', 1); (1, None, 2)] (* where m is the nfa created above *)
```

**e_closure m l**

* **Type:** `nfa_t -> int list -> int list`
* **Description:** This function takes as input an nfa and a list of states. The output will be a list of states (in any order, with no duplicates) that the NFA might be in making zero or more epsilon transitions, starting from the list of initial states given as an argument to e_closure.
* **Examples:**
```
e_closure m [0] = [0] (* where m is the nfa created above *)
e_closure m [1] = [1;2]
e_closure m [2]  = [2]
e_closure m [0;1] = [0;1;2] 
```
* **Explanation:**
  1. e_closure on `m` from `0` returns `[0]` since there is no where to go from `0` on an epsilon transition.
  2. e_closure on `m` from `1` returns `[1;2]` since from `1` you can get to `2` on an epsilon transition.
  3. e_closure on `m` from `2` returns `[2]` since there is no where to go from `2` on an epsilon transition.
  4. e_closure on `m` from `0` and `1` returns `[0;1;2]` since from `0` you can only get to yourself and from `1` you can get to `2` on an epsilon transition but from `2` you can't go anywhere.

**move m l c**

* **Type:** `nfa_t -> int list -> char -> int list`
* **Description:** This function takes as input an nfa, a list of initial states, and a character. The output will be a list of states (in any order, with no duplicates) that the NFA might be in after making one transition on the character, starting from one of the initial states given as an argument to move. This does NOT apply `e_closure` or take `None` edges, and rather only takes the `Some` edges.
* **Examples:**
```
move m [0] 'a' = [1] (* m is the nfa defined above *)
move m [1] 'a' = []
move m [2] 'a' = [] 
move m [0;1] 'a'  = [1]
```
* **Explanation:** 
  1. Move on `m` from `0` with `a` returns `[1]` since from 0 to 1 there is a transition with character `a`.
  2. Move on `m` from `1` with `a` returns `[]` since from 1 there is no transition with character `a`.
  3. Move on `m` from `2` with `a` returns `[]` since from 2 there is no transition with character `a`.
  4. Move on `m` from `0` and `1` with `a` returns `[1]` since from 0 to 1 there is a transition with character `a` but from 1 there was no transition with character `a`. 
  5. Notice that the NFA uses an implicit dead state. If s is a state in the input list and there are no transitions from s on the input character, then all that happens is that no states are added to the output list for s.

**nfa_to_dfa m**
* **Type:** `nfa_t -> nfa_t`
* **Description:** This function takes as input an NFA and converts it to an equivalent DFA. Notice the return type is an `nfa_t`. This is not a typo, every DFA is an NFA (not the other way around though), a restricted kind of NFA. Namely, it may not have non-deterministic transitions (i.e. epsilon transitions or more than one transition out of a state with the same symbol). The language recognized by an NFA is invariant under `nfa_to_dfa`. In other words, for all NFAs `m` and for all strings `s`, `accept m s = accept (nfa_to_dfa m) s`.
* **Hint:** Use the `int_list_to_int` function when implementing this conversion.

**accept m s**

* **Type:** `nfa_t -> string -> bool`
* **Description:** This function takes an NFA and a string, and returns true if the NFA accepts the string, and false otherwise. You will find the functions in the [`String` module][string doc] to be helpful.
* **Examples:**
```
accept n "" = false  (* n is the nfa defined above *)
accept n "ac" = true
accept n "abc" = false
accept n "abac" = true
```
* **Explanation:**
  1. accept on `n` with the string "" returns false because initially we are at our start state 0 and there are no characters to exhaust and we are not in a final state.
  2. accept on `n` with the string "ac" returns true because from 0 to 1 there is an 'a' transition and from 1 to 2 there is a 'c' transition and now that the string is empty and we are in a final state thus the nfa accepts "ac".
  3. accept on `n` with the string "abc" returns false because from 0 to 1 there is an 'a' transition but then to use the 'b' we go back from 1 to 0 and we are stuck because we need a 'c' transition yet there is only an 'a' transition. Since we are not in a final state thus the function returns false.
  4. accept on `n` with the string "abac" returns true because from 0 to 1 there is an 'a' transition but then to use the 'b' we go back from 1 to 0 and then we take an 'a' transition to go to state 1 again and then finally from 1 to 2 we exhaust our last character 'c' to make it to our final state. Since we are in a final state thus the nfa accepts "abac".

**stats m**

* **Type**: `nfa_t -> stats`
* **Description**: This function takes an NFA and returns a record of type `stats` containing information about the NFA. The record fields represent information about the NFA:
  * `num_states` represents the total number of states
  * `num_finals` represents the number of final states
  * `outgoing_counts` is an associative list mapping number of outgoing edges to the number of states with that number of outgoing edges. The list must be sorted by the the number of outgoing transitions.
* **Examples** (where `m` and `n` are nfas defined above):
```
stats m = (3, 1, [(0,1);(1,2)]) 
stats n = (3, 1, [(0,1);(1,1);(2,1)]) 
```
* **Explanation**: 
  1. Here `m` has a total of 3 states and 1 final state. The list is read as follows, `m` has 1 state with 0 outgoing edges and 2 states with 1 outgoing edge. Remember that the tuple is of the following format (n edges , x states).
  2. Here `n` has a total of 3 states and 1 final state and 1 state with 0 outgoing edges and 1 state with 1 outgoing edge and 1 state with 2 outgoing edges.
  3. Notice that the list should contain values that are greater than 0, if there are no states that have 3 outgoing transitions, do not to put (3,0) in the list, we will assume that if it's not in the list that the count is 0. stats counts only outgoing egdes

Part 2: Regular Expressions
---------------------------
The `Regexp` module contains the following type declaration:
```
type regexp_t =
  | Empty_String
  | Char of char
  | Union of regexp * regexp
  | Concat of regexp * regexp
  | Star of regexp
```
Here regexp_t is a user-defined OCaml variant datatype representing regular expressions
* `Empty_String` represents the regular expression recognizing the empty string (not the empty set!). Written as a formal regular expression, this would be `epsilon`.
* `Char c` represents the regular expression that accepts the single character c. Written as a formal regular expression, this would be `c`.
* `Union (r1, r2)` represents the regular expression that is the union of r1 and r2. For example, `Union(Char 'a', Char'b')` is the same as the formal regular expression `a|b`.
* `Concat (r1, r2)` represents the concatenation of r1 followed by r2. For example, `Concat(Char 'a', Char 'b')` is the same as the formal regular expresion `ab`.
* `Star r` represents the Kleene closure of regular expression r. For example, `Star (Union (Char 'a', Char 'b'))` is the same as the formal regular expression `(a|b)*`.

Now you must implement your own function to convert a regular expression (in the above format) to an NFA, which you can then use to match particular strings (by leveraging your `Nfa` module). You must also implement a function that turns `regexp_t` structures back into a string representation.

**regexp_to_nfa re**

* Type: `regexp_t -> nfa_t`
* Description: This function takes a regexp and returns an NFA that accepts the same language as the regular expression. Notice that as long as your NFA accepts the correct language, the structure of the NFA does not matter since the NFA produced will only be tested to see which strings it accepts.

**regexp_to_string re**

* **Type**: `regexp_t -> string`
* Description: This function takes a regular expression and returns a string representation of the regular expression in standard infix notation. How to deal with associativity and precedence is up to you - your output will be tested by running it back through the parser to check that your generated string is equivalent to the original regular expression, so excess parentheses will not be penalized.
* Examples:
```
regexp_to_string (Char 'a') = "a"
regexp_to_string (Union (Char 'a', Char 'b')) = "a|b"
regexp_to_string (Concat(Char 'a',Char 'b')) = "ab"
regexp_to_string (Concat(Char 'a',Concat(Char 'a',Char 'b'))) = "aab"
regexp_to_string (Star(Union(Char 'a',Empty_String))) = "(a|E)*" (* Note that 'E' represents epsilon! *)
regexp_to_string (Concat(Star(Union(Char 'a',Empty_String)),Union(Char 'a',Char 'b'))) = "(a|E)*(a|b)"
```
* **Hint:** You can do this as an in-order DFS traversal over the regexp data structure.
<!-- TODO is this too big a hint? -->

The rest of these functions are implemented for you as helpers. However, they rely on your code for correctness!

**string_to_nfa s**
* **Type:** `string -> nfa`
* **Description:** This function takes a string for a regular expression, parses the string, converts it into a regexp, and transforms it to an nfa, using your `regexp_to_nfa` function. As such, for this function to work, your `regexp_to_nfa` function must be working. In the starter files we have provided function `string_to_regexp` that parses strings into `regexp` values, described next.

**string_to_regexp s** (provided for you)
* **Type:** `string -> regexp`
* **Description:** This function takes a string for a regular expression, parses the string, and outputs its equivalent regexp. If the parser determines that the regular expression has illegal syntax, it will raise an IllegalExpression exception.
* **Examples:**
```
string_to_regexp "a" = Char 'a'
string_to_regexp "(a|b)" = Union (Char 'a', Char 'b')
string_to_regexp "ab" = Concat(Char 'a',Char 'b')
string_to_regexp "aab" = Concat(Char 'a',Concat(Char 'a',Char 'b'))
string_to_regexp "(a|E)*" = Star(Union(Char 'a',Empty_String))
string_to_regexp "(a|E)*(a|b)" = Concat(Star(Union(Char 'a',Empty_String)),Union(Char 'a',Char 'b'))

```
In a call to `string_to_regexp s` the string `s` may contain only parentheses, |, \*, a-z (lowercase), and E (for epsilon). A grammatically ill-formed string will result in `IllegalExpression` being thrown. Note that the precedence for regular expression operators is as follows, from highest(1) to lowest(4):

Precedence | Operator | Description
---------- | -------- | -----------
1 | () | parentheses
2 | * | closure
3 |  | concatenation
4 | &#124; | union

Also, note that all the binary operators are **right associative**. 


[list doc]: https://caml.inria.fr/pub/docs/manual-ocaml/libref/List.html
[string doc]: https://caml.inria.fr/pub/docs/manual-ocaml/libref/String.html
[modules doc]: https://realworldocaml.org/v1/en/html/files-modules-and-programs.html

<!-- These should always be left alone or at most updated -->
[pervasives doc]: https://caml.inria.fr/pub/docs/manual-ocaml/libref/Pervasives.html
[git instructions]: ../git_cheatsheet.md
[wikipedia inorder traversal]: https://en.wikipedia.org/wiki/Tree_traversal#In-order
