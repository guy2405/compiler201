#use "pc.ml";;

exception X_not_yet_implemented;;

exception X_this_should_not_happen;;

type number =
  | Int of int
  | Float of float;;

type sexpr =
  | Bool of bool
  | Nil
  | Number of number
  | Char of char
  | String of string
  | Symbol of string
  | Pair of sexpr * sexpr
  | TaggedSexpr of string * sexpr
  | TagRef of string;;

let rec sexpr_eq s1 s2 =
  match s1, s2 with
  | Bool b1, Bool b2 -> b1 = b2
  | Nil, Nil -> true
  | Number (Float f1), Number (Float f2) -> abs_float (f1 -. f2) < 0.001
  | Number (Int n1), Number (Int n2) -> n1 = n2
  | Char c1, Char c2 -> c1 = c2
  | String s1, String s2 -> s1 = s2
  | Symbol s1, Symbol s2 -> s1 = s2
  | Pair (car1, cdr1), Pair (car2, cdr2) -> sexpr_eq car1 car2 && sexpr_eq cdr1 cdr2
  | TaggedSexpr (name1, expr1), TaggedSexpr (name2, expr2) -> name1 = name2 && sexpr_eq expr1 expr2
  | TagRef name1, TagRef name2 -> name1 = name2
  | _ -> false;;

module Reader(*: sig
               val read_sexpr : string -> sexpr
               val read_sexprs : string -> sexpr list
               end *)=
struct
  let normalize_scheme_symbol str =
    if andmap (fun ch -> ch = lowercase_ascii ch) (string_to_list str)
    then str
    else Printf.sprintf "|%s|" str;;

  let _Bool_ =
    let _false_ = PC.pack (PC.word_ci "#f") (fun _ -> Bool false) in
    let _true_ = PC.pack (PC.word_ci "#t") (fun _ -> Bool true) in
    PC.disj _false_ _true_;;

  let _CharPrefix_ = PC.word "#\\";;

  let _VisibleSimpleChar_ = PC.range_ci '!' '~';;
  let _DigitChar_ = PC.range '0' '9';;
  let _af_ = PC.range_ci 'a' 'f'
  let _HexDigitChar_ = PC.disj _DigitChar_ _af_;;
  let _VisibleChar_ = PC.pack _VisibleSimpleChar_ (fun s -> Char s);;

  let _NamedChar_ =
    PC.disj_list [PC.pack (PC.word_ci "nul") (fun _ -> Char '\000');
                  PC.pack (PC.word_ci "newline") (fun _ -> Char '\n');
                  PC.pack (PC.word_ci "return") (fun _ -> Char '\r');
                  PC.pack (PC.word_ci "tab") (fun _ -> Char '\t');
                  PC.pack (PC.word_ci "page") (fun _ -> Char '\012');
                  PC.pack (PC.word_ci "space") (fun _ -> Char ' ')];;

  let _Char_ = PC.caten _CharPrefix_ (PC.disj _NamedChar_ _VisibleChar_);;

  let _Digit_ = PC.pack _DigitChar_ (fun s -> int_of_char s - (int_of_char '0'));;

  let _Natural_ =
    PC.pack (PC.plus _Digit_) (fun s -> List.fold_left
                                  (fun a b -> 10 * a + b)
                                  0
                                  s);;
  let _PositiveInteger_ = PC.pack (PC.caten (PC.char '+') _Natural_) (fun (_, s) -> s);;
  (*PC.test_string _PositiveInteger_ "+099";;)*)

  let _NegativeInteger_ = PC.pack (PC.caten (PC.char '-') _Natural_) (fun (_, s) -> s * (-1));;
  (* PC.test_string _NegativeInteger_ "-099";; *)

  let _Integer_ = PC.disj_list [_NegativeInteger_ ; _PositiveInteger_ ; _Natural_];;

  let _Float_ = PC.pack (PC.caten (PC.caten _Integer_ (PC.char '.')) _Natural_) (fun ((integer, _), nat) -> Float (float_of_string (string_of_int integer ^ "." ^ string_of_int nat)));;

  (* let read_sexpr string =
     let inputlst = string_to_list string in *)

  let read_sexprs string = raise X_not_yet_implemented;;

end;; (* struct Reader *)

PC.test_string Reader._Float_ "123.2";;