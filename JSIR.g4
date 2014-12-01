// JSIR grammar
/*
    - SSA-numbered bindings 
    - lexical scopes
    - fully dismantles control flow
    - support for CFGs with Entry and Exit BasicBlocks
    - the Blocks array in a ControlFlowGraph does NOT contain Entry and Exit BasicBlocks
*/
/* @namespace {Microsoft.CodeAnalysis.JSIRGrammar} */
grammar JSIR;
prog : Program;

Mode : 'strict' | 'non';
Boolean : 'true' | 'false';
Eval : 'eval';
Null : 'null';
This : 'this';
Undefined : 'undefined';
Number : NUMBER+;

Value :             
    Number
  | ConstantString
  | Boolean
  | Eval
  | Null
  | This
  | Undefined
  | Binding
  | FunctionReference   
;

Program : GlobalScope /* @name {functionDeclarations}*/FunctionDeclaration* ControlFlowGraph;

Statement :
      Assignment
    | Call  
    | DebuggerStatement
    | ReturnStatement
    ;

Call : StaticMethodCall | MethodCall | ConstructorCall ;

Assignment : 
      SimpleAssignment 
    | FieldAssignement 
    | ArrayAssignment     
           ;

SimpleAssignment     :   
    /* @name {LHS}*/Binding 
    '=' 
    /* @name {RHS}*/Expression;
FieldAssignement    :   
    /* @name {LHS}*/Binding 
    '.' /* @name {field}*/Binding 
    '=' 
    /* @name {RHS}*/Binding;
ArrayAssignment     :   
    /* @name {LHS}*/Binding 
    '[' 
    /* @name {index}*/ Binding 
    ']' 
    '=' 
    /* @name {RHS}*/Binding;

StaticMethodCall      : 
    /* @name {LHS}*/Binding
    '=' 
    /* @name {target}*/Binding
    '(' /* @name {arguments}*/Binding (',' /* @name {arguments}*/Binding)*')' 
    ';';

MethodCall :   
    /* @name {LHS}*/Binding 
    '=' 
    /* @name {target}*/Binding 
    '.' 
    /* @name {field}*/STRING
    '(' 
        /* @name {parameter}*/Binding ? (',' /* @name {parameter}*/Binding)* 
    ')';
ConstructorCall     :   
    /* @name {LHS}*/Binding 
    '=' 
    'new' 
    /* @name {function}*/Binding 
    '(' /* @name {parameter}*/Binding ? (',' /* @name {parameter}*/Binding)* ')'
    ;

Binding : Type /* @name {variable}*/ID '_' Version;// Scope;

// This is an uninterpreted type 
Type    : STRING;

/* This is intended to represent the SSA version */
Version : NUMBER+;

Scope : GlobalScope | LocalScope;
GlobalScope : 
    /* @name {bindings}*/Binding (/* @name {bindings}*/Binding)*
    ;
LocalScope : 
    'var' 
    '{' /* @name {parent}*/Scope '}'
    /* @name {bindings}*/Binding (/* @name {bindings}*/Binding)*
    ';';

Expression :
    FunctionDeclaration
  | ObjectLiteral
  | ArrayLiteral
  | ArrayReference
  | FieldReference
  | BinaryOperation
  | UnaryOperation
  | PhiFunction 
  | IotaFunction 
  | DeleteOperation  
  | Value
    ;

FunctionDeclaration:
'function' /* @name {name}*/ID 
    '(' /* @name {arguments}*/Binding (',' /* @name {arguments}*/Binding)* ')' 
    '{' 
    Mode 
    // entry and exit blocks are not included in the list blocks above
    /* @name {declarations}*/LocalScope 
    /* @name {nestedFunctions}*/FunctionDeclaration*
    ControlFlowGraph
    '}'
    ;
ControlFlowGraph :
    /* @name {entryBlock}*/BasicBlock 
    /* @name {blocks}*/BasicBlock* 
    /* @name {exitBlock}*/BasicBlock       
    ;

KeyValuePair : /* @name {field}*/STRING ':' /* @name {value}*/Value;
ObjectLiteral:
'{' /* @name {pair}*/KeyValuePair (',' /* @name {pair}*/KeyValuePair)* '}';

ArrayLiteral :
'[' /* @name {elements}*/Binding (',' /* @name {elements}*/Binding)* ']';
ArrayReference:
/* @name {target}*/Binding '[' /* @name {index}*/Binding ']';
FieldReference:
/* @name {target}*/Binding '.' /* @name {field}*/STRING;
DeleteOperation: 
      DeleteBinding 
    | DeleteArrayReference 
    | DeleteValue ;

DeleteBinding: 
    'delete' 
    /* @name {target}*/Binding 
    '.' 
    /* @name {field}*/Binding;
DeleteArrayReference: 
    'delete' 
    /* @name {target}*/Binding 
    '[' 
    /* @name {index}*/Binding 
    ']';
DeleteValue : 
    'delete' Binding;

BinaryOperation : 
    /* @name {LHS}*/Binding 
    BinaryOperator 
    /* @name {RHS}*/Binding;
UnaryOperation : 
    UnaryOperator Binding;

PhiFunction :
    'phi' 
    '('
    /* @name {bindings}*/Binding
    (',' /* @name {bindings}*/Binding)*
    ')'
    ;
IotaFunction : 
    'iota'             
    '('
    /* @name {variable}*/ID
    ')'
    ;

FunctionReference : 
    'ref'             
    '('
    /* @name {variable}*/ID
    ')'
    ;

DebuggerStatement : 'debugger';
ReturnStatement : 'return' /* @name {value} */Binding;

ConstantString : STRING;
Label: STRING;

Jump :
    SimpleGoto
  | ConditionalGoto
  | ThrowTo;

SimpleGoto : 'goto' /* @name {labels}*/Label (',' /* @name {labels}*/Label)*;
ConditionalGoto : 
    'goto' 
    /* @name {predicate}*/Binding 
    /* @name {label1}*/Label 
    /* @name {label2}*/Label;
ThrowTo : 
    'throwto' Binding;

BasicBlock :
    RegularBasicBlock |
    ExceptionalBasicBlock;

//  EmptyBasicBlock |
//EmptyBasicBlock : Label Jump;

RegularBasicBlock : Label Statement* Jump;

ExceptionalBasicBlock : 'set-catch-label' Label Binding Statement* Jump;

UnaryOperator    : '!'| '-' | '+' | '~'| 'typeof' | 'void' | '++'| '--';
BinaryOperator   : '+'|'-'|'^'|'|'|'*'|'/'|'%'| 
                   '&&' | '||' | 
                   '|' | '&' | '>>' | '<<'| '>>>' | 
                   '^' | 'instanceof' |
                   '==' | '===' | '!=' | '!=='
                 ;

///////////////////////////////

STRING
    :   '"' StringCharacters? '"' |
        '\'' StringCharacters? '\'' ;
StringCharacters
    :   ('a'..'z')|('A'..'Z')|('0'..'9') ;

fragment NUMBER : '0'..'9';
fragment ID : ('a'..'z' | 'A'..'Z' | '_' | '-' | 'a'..'z' | 'A'..'Z' | '$' | NUMBER)+;

//WS : ('\r'|'\n'|'\t') -> skip ;
//COMMENT : (
//	('#'| '//') ~[\r\n]* '\r'? '\n'
//		| '/*[' .*? ']*/
//	)  -> skip ;
