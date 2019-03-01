(* Name: Enock Gansou *)

type transition = int * char option * int
type stats = {num_states : int; num_finals : int; outgoing_counts : (int * int) list}

let get_next_gen () =
  let x = ref 0 in
  (fun () -> let r = !x in x := !x + 1; r)
let next = get_next_gen ()

let int_list_to_int =
  let next' = get_next_gen () in
  let tbl = Hashtbl.create 10 in
  let compare a b = if a < b then -1 else if a = b then 0 else 1 in
  (fun lst ->
      let slst = List.sort_uniq compare lst in
      if Hashtbl.mem tbl slst then Hashtbl.find tbl slst
    else let n = next' () in Hashtbl.add tbl slst n; n)

(* YOUR CODE BEGINS HERE *)

type nfa_t = {start : int ; finals : int list ; transitions : transition list }

let get_start m = m.start

let get_finals m = m.finals

let get_transitions m = m.transitions

let make_nfa ss fs ts = {start = ss; finals = fs; transitions = ts}

let rec contain x lst = List.fold_left(fun a h -> if h = x then true else a)false lst

let src_transitions m src opt = List.fold_left(fun acc (a,b,c) -> if (a = src && b = opt) then ((a,c)::acc) else acc) [] m.transitions

let rec helper_closure m ele lst visited = match lst with 
	[] -> ele::visited
	|(a,c)::t -> if  ((contain a visited = true) && (contain c visited = true)) then helper_closure m ele t visited
				else helper_closure m ele (t @ (src_transitions m c None)) (c::visited)

let e_closure m l = List.sort_uniq compare (List.fold_left(fun acc h ->((helper_closure m h (src_transitions m h None) []) @ acc)) [] l) 

let helper_move_one m x c = List.fold_left(fun acc (s,e) -> e::acc) [] (src_transitions m x (Some c)) 

let move m l c = List.sort_uniq compare (List.fold_left (fun a h -> (helper_move_one m h c) @ a ) [] l)

let all_states m = List.sort_uniq compare (List.fold_left(fun acc (a,b,c) -> a::c::acc ) [] m.transitions)  

let counts_one m x = List.fold_left(fun acc (a,b,c) -> if (a = x) then acc + 1 else acc) 0 m.transitions

let counts_all m = List.fold_left(fun acc h -> (counts_one m h)::acc ) [] (all_states m) 

let associat m = 
	let counts_one l x = List.fold_left(fun acc h -> if (h = x) then acc + 1 else acc) 0 l in 
	let lst = List.rev(List.sort compare (List.sort_uniq compare (counts_all m))) in 
			List.fold_left(fun acc h -> (h, counts_one (counts_all m) h)::acc )[] lst

let stats m = let num_s =  List.length (all_states m) in 
	let num_f = List.length (get_finals m) in 
	let assoc = associat m in
    {num_states = num_s ; num_finals = num_f ; outgoing_counts = assoc}

let all_characters m = List.sort_uniq Pervasives.compare (
		List.fold_left(fun acc (a,b,c) -> match b with Some x -> x::acc | None -> acc) [] m.transitions) 

let rec helper_nfa_to_dfa m lst visited (ts, finals) = match lst with 
	[]-> (ts, finals)
	|h::t -> 
		if (contain (int_list_to_int h) visited = false) then
			let characters = all_characters m in
			let to_visit = List.fold_left(fun acc head -> 
				let next_ele = e_closure m (move m h head) in
				if (next_ele  = []) then acc else next_ele::acc) t characters  in
			let visit = ((int_list_to_int h)::visited) in
			let transitions = (List.fold_left(fun acc head ->
				let next_ele = e_closure m (move m h head) in if next_ele  = [] then acc else
				let start_id = (int_list_to_int h) in
				let end_id = int_list_to_int (next_ele) in 
				(start_id, Some head, end_id)::acc ) ts characters) in
			let all_finals = if (List.fold_left(fun acc head -> 
				if (contain head (get_finals m)) then true else acc)false h) = true  
				then (int_list_to_int h)::finals else finals in 
			helper_nfa_to_dfa m to_visit visit (transitions, all_finals)
		else helper_nfa_to_dfa m t visited (ts, finals)


let nfa_to_dfa m = let s = e_closure m [(get_start m)] in let id = int_list_to_int s in 
	let (t, f) = helper_nfa_to_dfa m [s] [] ([],[]) in
	{start = id; finals = f; transitions = t}

let char_arr s =
  let rec exp i l =
    if i < 0 then l else exp (i - 1) (s.[i] :: l) in
  	exp (String.length s - 1) []

let accept m s = let f = if (String.length s = 0) then  (e_closure m [m.start])
 		else (List.fold_left (fun acc head -> e_closure m (move m acc head)) (e_closure m [m.start]) (char_arr s)) in
 		List.fold_left(fun acc head -> if (contain head (get_finals m)) then true else acc) false f
	
