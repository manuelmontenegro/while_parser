% Copyright 2019 Manuel Montenegro
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software
% and associated documentation files (the "Software"), to deal in the Software without restriction,
% including without limitation the rights to use, copy, modify, merge, publish, distribute,
% sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial
% portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
% NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
% OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Nonterminals exp stm stm_seq var_decl var_decls type fun_decl param_decls non_empty_param_decls 
      param_decl fun_decls program exps non_empty_exps non_empty_ids non_empty_types.
Terminals '+' '-' '*' '<=' '==' '?' ':' '(' ')' 'true' 'false' '&&' '||' ':=' ';' '::' ',' '.' '[' ']' '|'
          integer identifier
          skip if then else while do begin end var int bool function ret nil hd tl ifnil.
Rootsymbol program.


Nonassoc 100 ':='.
Nonassoc 200 '?'.
Nonassoc 200 ':'.
Right 300 '||'.
Right 400 '&&'.
Nonassoc 500 '<='.
Nonassoc 500 '=='.
Left 600 '+'.
Left 600 '-'.
Left 700 '*'.

exp -> integer      : { exp, literal, token_line('$1'), [{number, token_value('$1')}] }.
exp -> 'true'       : { exp, literal, token_line('$1'), [{boolean, true}]}.
exp -> 'false'      : { exp, literal, token_line('$1'), [{boolean, false}]}.
exp -> identifier   : { exp, variable, token_line('$1'), [{name, token_value('$1')}] }.
exp -> '-' integer  : { exp, literal, token_line('$1'), [{number, -token_value('$2')}]}.
exp -> exp '+' exp  : { exp, add, ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '-' exp  : { exp, sub, ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '*' exp  : { exp, mul, ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '<=' exp : { exp, leq, ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '==' exp : { exp, eq, ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '&&' exp : { exp, 'and', ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '||' exp : { exp, 'or', ast_line('$1'), [{lhs, '$1'}, {rhs, '$3'}] }.
exp -> exp '?' exp ':' exp 
                    : { exp, conditional, ast_line('$1'), [{condition, '$1'}, {'if', '$3'}, {'else', '$5'}] }.
exp -> '(' exp ')'  : '$2'.
exp -> '(' exp ',' non_empty_exps ')'  : {exp, tuple, token_line('$1'), [{components, ['$2' | '$4']}]}.
exp -> nil          : { exp, 'nil', token_line('$1'), []}.
exp -> exp '.' hd   : { exp, hd, ast_line('$1'), [{lhs, '$1'}]}.
exp -> exp '.' tl   : { exp, tl, ast_line('$1'), [{lhs, '$1'}]}.
exp -> '[' exp '|' exp ']'
                    : { exp, cons, token_line('$1'), [{head, '$2'}, {tail, '$4'}]}.

stm -> skip          
  : { stm, skip, token_line('$1'), [] }.
stm -> identifier ':=' exp
  : { stm, assignment, token_line('$1'), [{lhs, token_value('$1')}, {rhs, '$3'}] }.
stm -> identifier ':=' identifier '(' exps ')'
  : { stm, fun_app, token_line('$1'), [{lhs, token_value('$1')}, {fun_name, token_value('$3')}, {args, '$5'}] }.
stm -> '(' identifier ',' non_empty_ids ')' ':=' exp
  : { stm, tuple_assignment, token_line('$1'), [{lhs, [token_value('$2') | '$4']}, {rhs, '$7'}] }.
stm -> if exp then stm_seq else stm_seq end
  : { stm, 'if', token_line('$1'), [{condition, '$2'}, {'then', '$4'}, {'else', '$6'}] }.
stm -> while exp do stm_seq end
  : { stm, while, token_line('$1'), [{condition, '$2'}, {'body', '$4'}] }.
stm -> begin var_decls stm_seq end
  : { stm, block, token_line('$1'), [{decls, '$2'}, {body, '$3'}]}.
stm -> ifnil identifier then stm_seq else stm_seq end
  : { stm, ifnil, token_line('$1'), [{variable, token_value('$2')}, {'then', '$4'}, {'else', '$6'}]}.


program -> fun_decls stm_seq
  : {program, program, program_line('$1', '$2'), [{functions, '$1'}, {main_stm, '$2'}]}.

fun_decls -> '$empty'             : [].
fun_decls -> fun_decl fun_decls   : ['$1' | '$2'].

fun_decl -> function identifier '(' param_decls ')' ret '(' param_decl ')' stm_seq end
  : {declaration, fun_decl, token_line('$1'), [{function_name, token_value('$2')}, {params, '$4'}, {returns, '$8'}, {body, '$10'}]}.

stm_seq -> stm             : ['$1'].
stm_seq -> stm ';'         : ['$1'].
stm_seq -> stm ';' stm_seq : ['$1' | '$3'].

var_decls -> '$empty'                : [].
var_decls -> var_decl var_decls  : ['$1' | '$2'].

var_decl -> var identifier ':=' exp ';'           
  : {declaration, var_decl, token_line('$1'), [{lhs, token_value('$2')}, {rhs, '$4'}]}.
var_decl -> var identifier '::' type ':=' exp ';'
  : {declaration, var_decl, token_line('$1'), [{lhs, token_value('$2')}, {rhs, '$6'}, {type, '$4'}]}.


param_decls -> non_empty_param_decls       : '$1'.
param_decls -> '$empty'                    : [].

non_empty_param_decls -> param_decl                           : [ '$1' ].
non_empty_param_decls -> param_decl ',' non_empty_param_decls : [ '$1' | '$3' ].


param_decl -> identifier 
  : [{declaration, param_decl, token_line('$1'), [{variable, token_value('$1')}]}].
param_decl -> identifier '::' type 
  : [{declaration, param_decl, token_line('$1'), [{variable, token_value('$1')}, {type, '$3'}]}].

exps -> non_empty_exps : '$1'.
exps -> '$empty'       : [].

non_empty_exps -> exp                     : ['$1'].
non_empty_exps -> exp ',' non_empty_exps  : ['$1' | '$3'].

non_empty_ids -> identifier                    : [token_value('$1')].
non_empty_ids -> identifier ',' non_empty_ids  : [token_value('$1') | '$3'].

type -> int   : {type, int, token_line('$1'), []}.
type -> bool  : {type, bool, token_line('$1'), []}.
type -> '(' type ',' non_empty_types ')' : {type, tuple, token_line('$1'), [{components, ['$2' | '$4']}]}.
type -> '[' type ']'                     : {type, list, token_line('$1'), [{elements, '$2'}]}.
type -> '[' type ']' '+'                 : {type, non_empty_list, token_line('$1'), [{elements, '$2'}]}.

non_empty_types -> type                      : ['$1'].
non_empty_types -> type ',' non_empty_types  : ['$1' | '$3'].

Erlang code.

token_value({_, Val}) -> Val;
token_value({_, _, Val}) -> Val.
token_line({_, Line}) -> Line;
token_line({_, Line, _}) -> Line.



program_line([], [Stm | _]) -> ast_line(Stm);
program_line([D|_], _Stms) -> ast_line(D).

ast_line({_, _, Line, _}) -> Line.
