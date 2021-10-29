{
Функции выполнения Python скриптов.

Версия: 0.0.0.1
}
unit execfunc;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  uPSComponent,
  uPSCompiler,
  uPSRuntime,
  uPSUtils,
  dictionary,
  SysUtils,
  Variants;

type
  TICPascalScript = class(TPSScript)

  protected
    procedure CompilePascalScript(Sender: TPSScript);
    procedure VerifyPascalScript(Sender: TPSScript; Proc: TPSInternalProcedure;  const Decl: String; var Error: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  end;

//procedure CompilePascalScript(Sender: TPSScript);
//procedure VerifyPascalScript(Sender: TPSScript; Proc: TPSInternalProcedure;  const Decl: TBtString; var Error: Boolean);

{
Выполнить скрипт Pascal.
@param Script: Текст скрипта.
@param Context: Контекст выполнения скрипта.
@return: Строковое представление результата выполнения скрипта.
}
//function ExecutePascalScript(Script: AnsiString; Context: TStrDictionary): AnsiString;
function ExecutePascalScript(Script: AnsiString; Params: Array of Variant): AnsiString;

type
  //TScriptFunction = function (Context: AnsiString): AnsiString of object;
  TScriptFunction = function (Context: AnsiString): AnsiString;

var
  script: TScriptFunction;


implementation

uses
  log;

constructor TICPascalScript.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  self.OnCompile := @CompilePascalScript;
  self.OnVerifyProc := @VerifyPascalScript;
end;

destructor TICPascalScript.Destroy;
begin
  inherited Destroy;
end;

procedure TICPascalScript.CompilePascalScript(Sender: TPSScript);
begin
  Sender.AddFunction(@log.ServiceMsg,
                     'procedure ServiceMsg(sMsg: AnsiString; bForcePrint: Boolean = False; bForceLog: Boolean = False);');

end;

procedure TICPascalScript.VerifyPascalScript(Sender: TPSScript; Proc: TPSInternalProcedure;  const Decl: String; var Error: Boolean);
begin
  if Proc.Name = 'SCRIPTFUNCTION' then begin
    if not ExportCheck(Sender.Comp, Proc, [btString], [pmIn]) then
    begin
      Sender.Comp.MakeError('', ecCustomError, 'Function header for ScriptFunction does not match.');
      Error := True;
    end
    else
    begin
      Error := False;
    end;
  end
  else
    Error := False;
end;

{
Выполнить скрипт Pascal.
@param Script: Текст скрипта.
@param Context: Контекст выполнения скрипта.
@return: Строковое представление результата выполнения скрипта.
}
//function ExecutePascalScript(Script: AnsiString; Context: TStrDictionary): AnsiString;
function ExecutePascalScript(Script: AnsiString; Params: Array of Variant): AnsiString;
var
  pascal_script: TICPascalScript;
  script_text: AnsiString;
  compiled: Boolean;
  i: Integer;
  //method: TMethod;
  return_value: Variant;

begin
  Result := '';

  script_text := 'program Script;'#13#10;
  script_text := script_text + 'function ScriptFunction(Context: AnsiString): AnsiString;'#13#10;
  script_text := script_text + 'begin'#13#10;
  script_text := script_text + Script;
  script_text := script_text + #13#10;
  script_text := script_text + 'end;'#13#10;
  script_text := script_text + 'begin'#13#10;
  script_text := script_text + 'end.';
  log.InfoMsgFmt('Script <%s>', [script_text]);

  pascal_script := TICPascalScript(nil);

  try
    pascal_script.Script.Text := script_text;
    compiled := pascal_script.Compile;

    for i := 0 to pascal_script.CompilerMessageCount -1 do
      log.InfoMsgFmt('PascalScript. Компиляция <%s>', [pascal_script.CompilerMessages[i].MessageToString]);
    if compiled then
      log.InfoMsg('Succesfully compiled');

    if compiled then
    begin
      //method := pascal_script.GetProcMethod('SCRIPTFUNCTION');
      //script := TScriptFunction(pascal_script.GetProcMethod('SCRIPTFUNCTION'));
      //script := method As TScriptFunction;
      //if @script = nil then
      //begin
      //  raise Exception.Create('Unable to call ScriptFunction');
      //end;
      //Result := script('BlahBlahBlah');
      return_value := pascal_script.ExecuteFunction(Params, 'SCRIPTFUNCTION');
      Result := Variants.VarToStr(return_value);

      log.InfoMsgFmt('Result: <%s>', [Result]);
    end;

  except
    log.FatalMsgFmt('Ошибка выполнения выражения <%s>', [Script]);
  end;
  pascal_script.Destroy();
end;

end.
