(* CMSC 330 / Fall 2017 / Project 3 *)
(* Name: Enock Gansou*)
open Nfa

type regexp_t =
  | Empty_String
  | Char of char
  | Union of regexp_t * regexp_t
  | Concat of regexp_t * regexp_t
  | Star of regexp_t

let rec to_nfa re = match re with
  | Empty_String -> let a = next() in let b = next() in make_nfa a [b] [(a, None, b)]
  | Char c -> let a = next() in let b = next() in make_nfa a [b] [(a, Some c, b)]
  | Union (x, y) -> let a = next() in let b = next() in let first = (to_nfa x) in let second = (to_nfa y) in
    let link_start = [(a, None, get_start first); (a, None, get_start second)] in
    let link_end_first = List.fold_left(fun acc head -> (head, None, b)::acc)[] (get_finals first) in
    let link_end_second = List.fold_left(fun acc head -> (head, None, b)::acc)[] (get_finals second) in
    let first_transitons = (get_transitions first) in
    let second_transitons = (get_transitions second) in
    make_nfa a [b] (link_start@link_end_first@link_end_second@first_transitons@second_transitons)
  | Concat (x, y) -> let first = (to_nfa x) in let second = (to_nfa y) in
    let link = List.fold_left(fun acc head -> (head, None, get_start second)::acc)[] (get_finals first) in
    let first_transitons = (get_transitions first) in
    let second_transitons = (get_transitions second) in 
    make_nfa (get_start first) (get_finals second) (link@first_transitons@second_transitons)
  | Star (x) -> let a = next() in let elem = (to_nfa x) in 
    let link_start = [(a, None, get_start elem)] in 
    let link_end = List.fold_left(fun acc head -> (head, None, a)::acc)[] (get_finals elem) in 
    let transitons = (get_transitions elem) in
    make_nfa a [a] (link_start@link_end@transitons)

let regexp_to_nfa re = to_nfa re

let rec to_string re = match re with 
  | Empty_String -> "E"
  | Char (c) -> (String.make 1 c)
  | Union (x,y) -> "("^(to_string x)^"|"^(to_string y)^")"
  | Concat (x,y) -> "("^(to_string x)^(to_string y)^")"
  | Star (x) -> "("^"("^(to_string x)^")*"^")"

let regexp_to_string re = to_string re 

(*****************************************************************)
(* Below this point is parser code that YOU DO NOT NEED TO TOUCH *)
(*****************************************************************)

exception IllegalExpression of string

(* Scanner *)
type token =
  | Tok_Char of char
  | Tok_Epsilon
  | Tok_Union
  | Tok_Star
  | Tok_LParen
  | Tok_RParen
  | Tok_END

let tokenize str =
  let re_var = Str.regexp "[a-z]" in
  let re_epsilon = Str.regexp "E" in
  let re_union = Str.regexp "|" in
  let re_star = Str.regexp "*" in
  let re_lparen = Str.regexp "(" in
  let re_rparen = Str.regexp ")" in
  let rec tok pos s =
    if pos >= String.length s then
      [Tok_END]
    else begin
      if (Str.string_match re_var s pos) then
        let token = Str.matched_string s in
        (Tok_Char token.[0])::(tok (pos+1) s)
      else if (Str.string_match re_epsilon s pos) then
        Tok_Epsilon::(tok (pos+1) s)
      else if (Str.string_match re_union s pos) then
        Tok_Union::(tok (pos+1) s)
      else if (Str.string_match re_star s pos) then
        Tok_Star::(tok (pos+1) s)
      else if (Str.string_match re_lparen s pos) then
        Tok_LParen::(tok (pos+1) s)
      else if (Str.string_match re_rparen s pos) then
        Tok_RParen::(tok (pos+1) s)
      else
        raise (IllegalExpression("tokenize: " ^ s))
    end
  in
  tok 0 str

let tok_to_str t = ( match t with
      Tok_Char v -> (Char.escaped v)
    | Tok_Epsilon -> "E"
    | Tok_Union -> "|"
    | Tok_Star ->  "*"
    | Tok_LParen -> "("
    | Tok_RParen -> ")"
    | Tok_END -> "END"
  )

(*
   S -> A Tok_Union S | A
   A -> B A | B
   B -> C Tok_Star | C
   C -> Tok_Char | Tok_Epsilon | Tok_LParen S Tok_RParen

   FIRST(S) = Tok_Char | Tok_Epsilon | Tok_LParen
   FIRST(A) = Tok_Char | Tok_Epsilon | Tok_LParen
   FIRST(B) = Tok_Char | Tok_Epsilon | Tok_LParen
   FIRST(C) = Tok_Char | Tok_Epsilon | Tok_LParen
 *)

let parse_regexp (l : token list) = 
  let lookahead tok_list = match tok_list with
      [] -> raise (IllegalExpression "lookahead")
    | (h::t) -> (h,t)
  in

  let rec parse_S l =
    let (a1,l1) = parse_A l in
    let (t,n) = lookahead l1 in
    match t with
      Tok_Union -> (
        let (a2,l2) = (parse_S n) in
        (Union (a1,a2),l2)
      )
    | _ -> (a1,l1)

  and parse_A l =
    let (a1,l1) = parse_B l in
    let (t,n) = lookahead l1 in
    match t with
      Tok_Char c ->
      let (a2,l2) = (parse_A l1) in (Concat (a1,a2),l2)
    | Tok_Epsilon ->
      let (a2,l2) = (parse_A l1) in (Concat (a1,a2),l2)
    | Tok_LParen ->
      let (a2,l2) = (parse_A l1) in (Concat (a1,a2),l2)
    | _ -> (a1,l1)

  and parse_B l =
    let (a1,l1) = parse_C l in
    let (t,n) = lookahead l1 in
    match t with
      Tok_Star -> (Star a1,n)
    | _ -> (a1,l1)

  and parse_C l =
    let (t,n) = lookahead l in
    match t with
      Tok_Char c -> (Char c, n)
    | Tok_Epsilon -> (Empty_String, n)
    | Tok_LParen ->
      let (a1,l1) = parse_S n in
      let (t2,n2) = lookahead l1 in
      if (t2 = Tok_RParen) then
        (a1,n2)
      else
        raise (IllegalExpression "parse_C 1")
    | _ -> raise (IllegalExpression "parse_C 2")
  in
  let (rxp, toks) = parse_S l in
  match toks with
  | [Tok_END] -> rxp
  | _ -> raise (IllegalExpression "parse didn't consume all tokens")

let string_to_regexp str = parse_regexp @@ tokenize str

let string_to_nfa str = regexp_to_nfa @@ string_to_regexp str
