{
Функции выполнения Python скриптов.

Версия: 0.0.1.3
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

const
  EXEC_SIGNATURE: AnsiString = 'EXEC: ';

type
  TICPascalScript = class(TPSScript)
  private
    FContext: dictionary.TStrDictionary;

  protected
    procedure CompilePascalScript(Sender: TPSScript);
    procedure VerifyPascalScript(Sender: TPSScript; Proc: TPSInternalProcedure;  const Decl: String; var Error: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    property Context: dictionary.TStrDictionary read FContext write FContext;

  end;

{
Выполнить скрипт Pascal.
@param Script: Текст скрипта.
@param Context: Контекст выполнения скрипта.
@return: Строковое представление результата выполнения скрипта.
}
function ExecutePascalScript(Script: AnsiString; Context: dictionary.TStrDictionary = nil): Variant;


implementation

uses
  log,
  strfunc,
  dtfunc,
  filefunc;

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
  // Добавить стандартные функции в область видимости скрипта
  //   Функции работы со строками
  Sender.AddFunction(@Format,
                     'function Format(const Format: String; const Args: Array of const): String;');
  Sender.AddFunction(@strfunc.Replace,
                     'function Replace(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString): String;');
  //   Функции работы с датой/временем
  Sender.AddFunction(@dtfunc.GetNowStr,
                     'function GetNowStr(): String;');
  Sender.AddFunction(@dtfunc.GetTodayStr,
                     'function GetTodayStr(): String;');
  Sender.AddFunction(@dtfunc.GetNowFormat,
                     'function GetNowFormat(sDateTimeFmt: String): String;');
  Sender.AddFunction(@dtfunc.GetTodayFormat,
                     'function GetTodayFormat(sDateTimeFmt: String): String;');
  //   Функции работы с файлами
  Sender.AddFunction(@filefunc.GetHomeDir,
                     'function GetHomeDir(): String;');

  //Sender.AddFunction(@log.ServiceMsg,
  //                   'procedure ServiceMsg(sMsg: AnsiString; bForcePrint: Boolean = False; bForceLog: Boolean = False);');


end;

procedure TICPascalScript.VerifyPascalScript(Sender: TPSScript; Proc: TPSInternalProcedure;  const Decl: String; var Error: Boolean);
begin
  //if Proc.Name = 'SCRIPTFUNCTION' then begin
  //  if not ExportCheck(Sender.Comp, Proc, {$IFDEF UNICODE}[btUnicodeString, btUnicodeString]{$ELSE}[btString, btString]{$ENDIF}, [pmIn]) then
  //  begin
  //    Sender.Comp.MakeError('', ecCustomError, 'Function header for ScriptFunction does not match.');
  //    Error := True;
  //  end
  //  else
  //  begin
  //    Error := False;
  //  end;
  //end
  //else
    Error := False;
end;

{
Выполнить скрипт Pascal.
@param Script: Текст скрипта.
@param Context: Контекст выполнения скрипта.
@return: Строковое представление результата выполнения скрипта.
}
function ExecutePascalScript(Script: AnsiString; Context: TStrDictionary): Variant;
var
  pascal_script: TICPascalScript;
  script_text: AnsiString;
  compiled: Boolean;
  i: Integer;
  params: Array of Variant;

begin
  Result := nil;

  // Отбросить сигнатуру если она присутствует
  if strfunc.IsStartsWith(Script, EXEC_SIGNATURE) then
     Script := strfunc.ReplaceStart(Script, EXEC_SIGNATURE, '');

  // Заполнение тела функции
  script_text := 'program Script;'#13#10;
  script_text := script_text + 'function ScriptFunction(';
  if Context <> nil then
    for i := 0 to Context.Count - 1 do
    begin
      script_text := script_text + Context.GetKey(i) + ': String';
      if i < (Context.Count - 1) then
        script_text := script_text + '; ';
    end;
  script_text := script_text + '): String;'#13#10;
  script_text := script_text + 'begin'#13#10;
  script_text := script_text + Script;
  script_text := script_text + #13#10;
  script_text := script_text + 'end;'#13#10;
  script_text := script_text + 'begin'#13#10;
  script_text := script_text + 'end.';
  log.InfoMsgFmt('Script <%s>', [script_text]);

  pascal_script := TICPascalScript.Create(nil);
  pascal_script.Context := Context;

  try
    // Компиляция
    pascal_script.Script.Text := script_text;
    compiled := pascal_script.Compile;

    // Вывод ошибок компиляции
    for i := 0 to pascal_script.CompilerMessageCount -1 do
      if strfunc.IsStartsWith(pascal_script.CompilerMessages[i].MessageToString, '[Error]') then
        log.ErrorMsgFmt('PascalScript. Компиляция <%s>', [pascal_script.CompilerMessages[i].MessageToString])
      else
        log.WarningMsgFmt('PascalScript. Компиляция <%s>', [pascal_script.CompilerMessages[i].MessageToString]);
    if compiled then
      log.InfoMsg('Succesfully compiled');

    if compiled then
    begin
      // Выполнить функцию
      if Context <> nil then
      begin
        SetLength(params, Context.Count);
        for i := 0 to Context.Count - 1 do
        begin
          params[i] := Context.GetStrValue(Context.GetKey(i));
          log.InfoMsgFmt('Param: <%s : %s>', [Context.GetKey(i), Variants.VarToStr(params[i])]);
        end;
      end
      else
        SetLength(params, 0);
      Result := pascal_script.ExecuteFunction(params, 'SCRIPTFUNCTION');
      log.InfoMsgFmt('Result: <%s>', [Variants.VarToStr(Result)]);
    end;

  except
    log.FatalMsgFmt('Ошибка выполнения выражения <%s>', [Script]);
  end;
  // Обязательно удаляем объект скрипта
  pascal_script.Destroy();
end;

end.
