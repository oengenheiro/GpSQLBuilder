///<summary>Serializers working on the SQL AST.</summary>
///<author>Primoz Gabrijelcic</author>
///<remarks><para>
///Copyright (c) 2015, Primoz Gabrijelcic
///All rights reserved.
///
///Redistribution and use in source and binary forms, with or without
///modification, are permitted provided that the following conditions are met:
///
///* Redistributions of source code must retain the above copyright notice, this
///  list of conditions and the following disclaimer.
///
///* Redistributions in binary form must reproduce the above copyright notice,
///  this list of conditions and the following disclaimer in the documentation
///  and/or other materials provided with the distribution.
///
///* Neither the name of GpSQLBuilder nor the names of its
///  contributors may be used to endorse or promote products derived from
///  this software without specific prior written permission.
///
///THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
///AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
///IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
///DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
///FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
///DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
///SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
///CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
///OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
///OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///
///   Author            : Primoz Gabrijelcic
///   Creation date     : 2015-04-20
///   Last modification : 2015-04-29
///   Version           : 1.0
///</para><para>
///   History:
///     1.0: 2015-04-29
///       - Released.
///</para></remarks>

unit GpSQLBuilder.Serialize;

interface

uses
  GpSQLBuilder.AST;

type
  IGpSQLExpressionSerializer = interface ['{A0CCE046-081E-4B12-8A0A-B5D7B9D0308F}']
    function AsString: string;
  end; { IGpSQLExpressionSerializer }

  IGpSQLCaseSerializer = interface ['{1A56402D-2BFA-4282-B8EC-5FF80FB42994}']
    function AsString: string;
  end; { IGpSQLCaseSerializer }

  IGpSQLASTSerializer = interface ['{E6355E23-1D91-4536-A693-E1E33B0E2707}']
    function AsString: string;
  end; { IGpSQLASTSerializer }

function CreateSQLSerializer(const expr: IGpSQLExpression): IGpSQLExpressionSerializer; overload;
function CreateSQLSerializer(const caseExpr: IGpSQLCase): IGpSQLCaseSerializer; overload;
function CreateSQLSerializer(const ast: IGpSQLAST): IGpSQLASTSerializer; overload;

implementation

uses
  System.SysUtils,
  GpSQLBuilder;

type
  TGpSQLExpressionSerializer = class(TInterfacedObject, IGpSQLExpressionSerializer)
  strict private
    FExpr: IGpSQLExpression;
  strict protected
    function  SerializeExpression(const expression: IGpSQLExpression; addParens: boolean = false): string;
  public
    constructor Create(const AExpr: IGpSQLExpression);
    function  AsString: string;
  end; { TGpSQLExpressionSerializer }

  TGpSQLCaseSerializer = class(TInterfacedObject, IGpSQLCaseSerializer)
  strict private
    FCase: IGpSQLCase;
  strict protected
    function SerializeExpression(const expression: IGpSQLExpression): string;
  public
    constructor Create(const ACase: IGpSQLCase);
    function  AsString: string;
  end; { TGpSQLCaseSerializer }

  TGpSQLSerializer = class(TInterfacedObject, IGpSQLASTSerializer)
  strict private
    FAST : IGpSQLAST;
  strict protected
    function  SerializeCase(const caseExpr: IGpSQLCase): string;
    function  SerializeColumns(const columns: IGpSQLColumns): string;
    function  SerializeDirection(direction: TGpSQLOrderByDirection): string;
    function  SerializeExpression(const expression: IGpSQLExpression): string;
    function  SerializeGroupBy: string;
    function  SerializeHaving: string;
    function  SerializeJoins: string;
    function  SerializeJoinType(const join: IGpSQLJoin): string;
    function  SerializeName(const name: IGpSQLName): string;
    function  SerializeOrderBy: string;
    function  SerializeSelect: string;
    function  SerializeSelectQualifiers(const qualifiers: IGpSQLSelectQualifiers): string;
    function  SerializeWhere: string;
  public
    constructor Create(const AAST: IGpSQLAST);
    function  AsString: string;
  end; { TGpSQLSerializer }

{ globals }

function AddToList(const aList, delim, newElement: string): string;
begin
  Result := aList;
  if Result <> '' then
    Result := Result + delim;
  Result := Result + newElement;
end; { AddToList }

function Concatenate(const elements: array of string; delimiter: string = ' '): string;
var
  s: string;
begin
  Result := '';
  for s in elements do
    if s <> '' then
      Result := AddToList(Result, delimiter, s);
end; { Concatenate }

{ exports }

function CreateSQLSerializer(const expr: IGpSQLExpression): IGpSQLExpressionSerializer;
begin
  Result := TGpSQLExpressionSerializer.Create(expr);
end; { CreateSQLSerializer }

function CreateSQLSerializer(const caseExpr: IGpSQLCase): IGpSQLCaseSerializer;
begin
  Result := TGpSQLCaseSerializer.Create(caseExpr);
end; { CreateSQLSerializer }

function CreateSQLSerializer(const ast: IGpSQLAST): IGpSQLASTSerializer;
begin
  Result := TGpSQLSerializer.Create(ast);
end; { CreateSQLSerializer }

{ TGpSQLExpressionSerializer }

function TGpSQLExpressionSerializer.AsString: string;
begin
  Result := SerializeExpression(FExpr);
end; { TGpSQLExpressionSerializer.AsString }

constructor TGpSQLExpressionSerializer.Create(const AExpr: IGpSQLExpression);
begin
  inherited Create;
  FExpr := AExpr;
end; { TGpSQLExpressionSerializer.Create }

function TGpSQLExpressionSerializer.SerializeExpression(
  const expression: IGpSQLExpression; addParens: boolean): string;
begin
  if expression.IsEmpty then
    Result := ''
  else
    case expression.Operation of
      opNone: if addParens then
                Result := '(' + expression.Term + ')'
              else
                Result := expression.Term;
      opAnd:  Result := Concatenate([
                          SerializeExpression(expression.Left, true),
                          'AND',
                          SerializeExpression(expression.Right, true)
                        ]);
      opOr:   Result := '(' + Concatenate([
                          SerializeExpression(expression.Left, true),
                          'OR',
                          SerializeExpression(expression.Right, true)
                        ]) + ')';
      else raise Exception.Create('TGpSQLSerializer.SerializeExpression: Unknown operation');
    end;
end; { TGpSQLExpressionSerializer.SerializeExpression }

{ TGpSQLCaseSerializer }

constructor TGpSQLCaseSerializer.Create(const ACase: IGpSQLCase);
begin
  inherited Create;
  FCase := ACase;
end; { TGpSQLCaseSerializer.Create }

function TGpSQLCaseSerializer.AsString: string;
var
  i : integer;
  wt: IGpSQLCaseWhenThen;
begin
  Result := 'CASE';
  if not FCase.CaseExpression.IsEmpty then
    Result := Concatenate([Result, SerializeExpression(FCase.CaseExpression)]);
  for i := 0 to FCase.WhenList.Count - 1 do begin
    Result := Concatenate([Result, 'WHEN']);
    wt := FCase.WhenList[i];
    if not wt.WhenExpression.IsEmpty then
      Result := Concatenate([Result, SerializeExpression(wt.WhenExpression)]);
    Result := Concatenate([Result, 'THEN', SerializeExpression(wt.ThenExpression)]);
  end;
  if not FCase.ElseExpression.IsEmpty then
    Result := Concatenate([Result, 'ELSE', SerializeExpression(FCase.ElseExpression)]);
  Result := Concatenate([Result, 'END']);
end; { TGpSQLCaseSerializer.AsString }

function TGpSQLCaseSerializer.SerializeExpression(const expression: IGpSQLExpression):
  string;
begin
  Result := CreateSQLSerializer(expression).AsString;
end; { TGpSQLCaseSerializer.SerializeExpression }

{ TGpSQLSerializer }

constructor TGpSQLSerializer.Create(const AAST: IGpSQLAST);
begin
  inherited Create;
  FAST := AAST;
end; { TGpSQLSerializer.Create }

function TGpSQLSerializer.AsString: string;
begin
  Result := Concatenate([
    SerializeSelect,
    SerializeJoins,
    SerializeWhere,
    SerializeGroupBy,
    SerializeHaving,
    SerializeOrderBy]);
end; { TGpSQLSerializer.AsString }

function TGpSQLSerializer.SerializeCase(const caseExpr: IGpSQLCase): string;
begin
  Result := CreateSQLSerializer(caseExpr).AsString;
end; { TGpSQLSerializer.SerializeCase }

function TGpSQLSerializer.SerializeColumns(const columns: IGpSQLColumns): string;
var
  i         : integer;
  orderByCol: IGpSQLOrderByColumn;
begin
  Result := '';
  for i := 0 to columns.Count - 1 do begin
    Result := Concatenate([Result, SerializeName(columns[i])], ', ');
    if Supports(columns[i], IGpSQLOrderByColumn, orderByCol) then
      Result := Concatenate([Result, SerializeDirection(orderByCol.Direction)]);
  end;
end; { TGpSQLSerializer.SerializeColumns }

function TGpSQLSerializer.SerializeDirection(direction: TGpSQLOrderByDirection): string;
begin
  case direction of
    dirAscending:  Result := '';
    dirDescending: Result := 'DESC';
    else raise Exception.Create('TGpSQLSerializer.SerializeDirection: Unknown direction');
  end;
end; { TGpSQLSerializer.SerializeDirection }

function TGpSQLSerializer.SerializeExpression(const expression: IGpSQLExpression): string;
begin
  Result := CreateSQLSerializer(expression).AsString;
end; { TGpSQLSerializer.SerializeExpression }

function TGpSQLSerializer.SerializeGroupBy: string;
begin
  if FAST.GroupBy.IsEmpty then
    Result := ''
  else
    Result := Concatenate(['GROUP BY', SerializeColumns(FAST.GroupBy.Columns)]);
end; { TGpSQLSerializer.SerializeGroupBy }

function TGpSQLSerializer.SerializeHaving: string;
begin
  if FAST.Having.IsEmpty then
    Result := ''
  else
    Result := Concatenate(['HAVING', SerializeExpression(FAST.Having.Expression)]);
end; { TGpSQLSerializer.SerializeHaving }

function TGpSQLSerializer.SerializeJoins: string;
var
  iJoin: integer;
  join : IGpSQLJoin;
begin
  Result := '';
  for iJoin := 0 to FAST.Joins.Count - 1 do begin
    join := FAST.Joins[iJoin];
    Result := Concatenate([Result, SerializeJoinType(join), 'JOIN',
       SerializeName(join.JoinedTable),
      'ON', SerializeExpression(join.Condition)]);
  end;
end; { TGpSQLSerializer.SerializeJoins }

function TGpSQLSerializer.SerializeJoinType(const join: IGpSQLJoin): string;
begin
  case join.JoinType of
    jtInner: Result := 'INNER';
    jtLeft:  Result := 'LEFT';
    jtRight: Result := 'RIGHT';
    jtFull:  Result := 'FULL';
    else raise Exception.Create('Error Message');
  end;
end; { TGpSQLSerializer.SerializeJoinType }

function TGpSQLSerializer.SerializeName(const name: IGpSQLName): string;
begin
  if assigned(name.&Case) then
    Result := '(' + SerializeCase(name.&Case) + ')'
  else
    Result := name.Name;
  if name.Alias <> '' then
    Result := Result + ' AS ' + name.Alias;
end; { TGpSQLSerializer.SerializeName }

function TGpSQLSerializer.SerializeOrderBy: string;
begin
  if FAST.OrderBy.IsEmpty then
    Result := ''
  else
    Result := Concatenate(['ORDER BY', SerializeColumns(FAST.OrderBy.Columns)]);
end; { TGpSQLSerializer.SerializeOrderBy }

function TGpSQLSerializer.SerializeSelect: string;
begin
  if FAST.Select.IsEmpty then
    Result := ''
  else
    Result := Concatenate(['SELECT', SerializeSelectQualifiers(FAST.Select.Qualifiers),
      SerializeColumns(FAST.Select.Columns), 'FROM', SerializeName(FAST.Select.TableName)]);
end; { TGpSQLSerializer.SerializeSelect }

function TGpSQLSerializer.SerializeSelectQualifiers(
  const qualifiers: IGpSQLSelectQualifiers): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to qualifiers.Count - 1 do
    case qualifiers[i].Qualifier of
      sqFirst: Result := AddToList(Result, ' ', Concatenate(['FIRST', IntToStr(qualifiers[i].Value)]));
      sqSkip:  Result := AddToList(Result, ' ', Concatenate(['SKIP', IntToStr(qualifiers[i].Value)]));
      else raise Exception.Create('TGpSQLSerializer.SerializeSelectQualifiers: Unknown qualifier');
    end;
end; { TGpSQLSerializer.SerializeSelectQualifiers }

function TGpSQLSerializer.SerializeWhere: string;
begin
  if FAST.Where.IsEmpty then
    Result := ''
  else
    Result := Concatenate(['WHERE', SerializeExpression(FAST.Where.Expression)]);
end; { TGpSQLSerializer.SerializeWhere }

end.