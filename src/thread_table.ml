type 'v bucket = Nil | Cons of int * 'v * 'v bucket

type 'v t = {
  mutable rehash : int;
  mutable buckets : 'v bucket array;
  mutable length : int;
}

let[@tail_mod_cons] rec remove_first removed k' = function
  | Nil -> Nil
  | Cons (k, v, kvs) ->
      if k == k' then begin
        removed := true;
        kvs
      end
      else Cons (k, v, remove_first removed k' kvs)

let[@inline] remove_first removed k' = function
  | Nil -> Nil
  | Cons (k, v, kvs) ->
      if k == k' then begin
        removed := true;
        kvs
      end
      else Cons (k, v, remove_first removed k' kvs)

let rec find k' = function
  | Nil -> raise Not_found
  | Cons (k, v, kvs) -> if k == k' then v else find k' kvs

let[@tail_mod_cons] rec filter bit chk = function
  | Nil -> Nil
  | Cons (k, v, kvs) ->
      if k land bit = chk then Cons (k, v, filter bit chk kvs)
      else filter bit chk kvs

let[@inline] filter bit chk = function
  | Nil -> Nil
  | Cons (k, _, Nil) as kvs -> if k land bit = chk then kvs else Nil
  | Cons (k, v, kvs) ->
      if k land bit = chk then Cons (k, v, filter bit chk kvs)
      else filter bit chk kvs

let[@tail_mod_cons] rec append kvs tail =
  match kvs with Nil -> tail | Cons (k, v, kvs) -> Cons (k, v, append kvs tail)

let[@inline] append kvs tail =
  match kvs with Nil -> tail | Cons (k, v, kvs) -> Cons (k, v, append kvs tail)

let min_buckets = 4
and max_buckets_div_2 = (Sys.max_array_length + 1) asr 1

let create () = { rehash = 0; buckets = Array.make min_buckets Nil; length = 0 }
let length t = t.length

let find t k' =
  let buckets = t.buckets in
  let n = Array.length buckets in
  let i = k' land (n - 1) in
  find k' (Array.unsafe_get buckets i)

let rec maybe_rehash t =
  let old_buckets = t.buckets in
  let new_n = t.rehash in
  if new_n <> 0 then
    let old_n = Array.length old_buckets in
    let new_buckets = Array.make new_n Nil in
    if old_n < new_n then
      let new_bit = new_n lsr 1 in
      let rec loop i =
        if t.buckets != old_buckets then maybe_rehash t
        else if i < old_n then begin
          let kvs = Array.unsafe_get old_buckets i in
          Array.unsafe_set new_buckets i (filter new_bit 0 kvs);
          Array.unsafe_set new_buckets (i lor new_bit)
            (filter new_bit new_bit kvs);
          loop (i + 1)
        end
        else begin
          t.buckets <- new_buckets;
          t.rehash <- 0
        end
      in
      loop 0
    else
      let old_bit = old_n lsr 1 in
      let rec loop i =
        if t.buckets != old_buckets then maybe_rehash t
        else if i < new_n then begin
          Array.unsafe_set new_buckets i
            (append
               (Array.unsafe_get old_buckets (i + old_bit))
               (Array.unsafe_get old_buckets i));
          loop (i + 1)
        end
        else begin
          t.buckets <- new_buckets;
          t.rehash <- 0
        end
      in
      loop 0

let[@inline] maybe_rehash t = if t.rehash <> 0 then maybe_rehash t

(* Explicitly disallow inlining of [add] and [remove] to avoid allocations
   being moved inside their bodies. *)

let[@inline never] rec add t k' v' =
  maybe_rehash t;
  let buckets = t.buckets in
  let n = Array.length buckets in
  let i = k' land (n - 1) in
  let before = Array.unsafe_get buckets i in
  let after = Cons (k', v', before) in
  if
    t.rehash <> 0 || buckets != t.buckets
    || before != Array.unsafe_get buckets i
  then add t k' v'
  else begin
    Array.unsafe_set buckets i after;
    let length = t.length + 1 in
    t.length <- length;
    if n < length && n < max_buckets_div_2 then t.rehash <- n * 2
  end

let[@inline never] rec remove t k' =
  let removed = ref false in
  maybe_rehash t;
  let buckets = t.buckets in
  let n = Array.length buckets in
  let i = k' land (n - 1) in
  let before = Array.unsafe_get buckets i in
  let after = remove_first removed k' before in
  if
    t.rehash <> 0 || buckets != t.buckets
    || before != Array.unsafe_get buckets i
  then remove t k'
  else if !removed then begin
    Array.unsafe_set buckets i after;
    let length = t.length - 1 in
    t.length <- length;
    if length * 4 < n && min_buckets < n then t.rehash <- n asr 1
  end
