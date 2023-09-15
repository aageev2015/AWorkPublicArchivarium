var RecordsLoggedInterval = 100000;
var ExportDataFileName;
var FirebirdDatabaseName;
var QuitOnError = false;

var connFirebird = null;

var Stream;
var FSO;
var Shell;
var Timers = [];

//Consts
var adTypeBinary = 1;
var adTypeText = 2;

// State flags
var IsErrorFlag = false;

function ClearTimer(Code) {
	var Timer = Timers[Code];
	if (Timer == undefined) {
		return;
	}
	Timer.StartTime = null;
	Timer.CurrentValue = null;
}

function StartTimer(Code) {
	var Timer = Timers[Code];
	if (Timer == undefined) {
		Timer = {StartTime: (new Date()), CurrentValue: 0}
		Timers[Code] = Timer;
	} else {
		if (Timer.StartTime == null) {
			var Now = new Date();
			Timer.StartTime = Now;
		}		
	}
}

function StopTimer(Code) {
	var Timer = Timers[Code];
	var Now = new Date();
	Timer.CurrentValue += (Now - Timer.StartTime);
	Timer.StartTime = null;
}

function GetTimerValue(Code) { // in minutes
	var Timer = Timers[Code];
	var Now = new Date();
	return Timer.CurrentValue + (Now - Timer.StartTime);
}

function MillisecondsToReadableText(Milliseconds) {
	var Result = Milliseconds/1000;
	if (Result < 60) {
		return Result + ' seconds';
	}
	Result = Result/60;
	if (Result < 60) {
		return Result + ' minutes';
	}
	Result = Result/60;
	if (Result < 24) {
		return Result + ' hours';
	}	
	return Result/24 + ' days';
}

function GetTimerValueAsStr(Code) {
	var Milliseconds = GetTimerValue(Code);
	return MillisecondsToReadableText(Milliseconds);
}

function DateToStr(DateValue) {
	return DateValue.getDate() + 'd.' + (DateValue.getMonth() + 1) + 'm.' + DateValue.getYear();
}

function DateTimeToStr(DateValue) {
	return DateToStr(DateValue) + ' ' + DateValue.getHours() + ':' + DateValue.getMinutes();
}

function Log(LogString) {
	WScript.StdOut.WriteLine(LogString);
}

function Trim(Str) {
	if (Str == null) {
		return null;
	}
	return (Str+'').replace(/^\s+/, '').replace(/\s+$/, '');
}


function Initialize() {
	Log("Initializing");
	connFirebird = new ActiveXObject("ADODB.Connection");
	Stream = new ActiveXObject("ADODB.Stream");
	FSO = new ActiveXObject('Scripting.FileSystemObject');
	Shell = new ActiveXObject("WScript.Shell");
}

function CloseConnection(Conn) {
	if (Conn.State != 0) {
		Conn.Close();
	}
}

function Finalize() {
	Log("Disconnecting");
	CloseConnection(connFirebird);
	Log("Finished");
	connFirebird = null;
	Stream = null;
	Shell = null;
	FSO = null;
}

function InitializeConnection(conn, ConnectionString) {
	conn.ConnectionTimeOut = 15;
	conn.CommandTimeout = 30;
	conn.ConnectionString = ConnectionString;
	var IsConnectionError = false;
	try {
		conn.Open();
	} catch(e) {
		Log('-----Connecting error-----');
		Log(ConnectionString);
		Log('***ERROR****');
		Log(e.message);
		Log('');
		IsConnectionError = true;
	}
	if (IsConnectionError) {
		DoQuit();
	}
}

function Connect() {	
	FirebirdDatabaseName = WScript.Arguments(0);
	Log("Connecting to Firebird: " + FirebirdDatabaseName);
	InitializeConnection(connFirebird, 
	"Driver={Firebird/InterBase(r) driver};Uid=SYSDBA;Pwd=masterkey; DbName="+FirebirdDatabaseName+";"
	);
}

function DoQuit() {
	Finalize();
	WScript.Quit();
}

function WriteQueryErrorLog(QueryText, ErrorMessage) {
	Log('------------ERROR on Execute Query-------');
	Log(QueryText);
	Log('***ErrorText***');
	Log(ErrorMessage);
	Log('');
}

function SafeExecuteQuery(conn, QueryText) {
	try {
		conn.Execute(QueryText);
	} catch(e)	{
		IsErrorFlag = true;
		WriteQueryErrorLog(QueryText, e.message);
	}
}

function SafeGetQueryData(conn, QueryText) {
	var Result;
	try {
		Result = conn.Execute(QueryText);
	} catch(e)	{
		IsErrorFlag = true;
		WriteQueryErrorLog(QueryText, e.message);
	}
	return Result;
}

function binToHex(binStr){ 
	var xmldom = new ActiveXObject("Microsoft.XMLDOM"); 
	var binObj= xmldom.createElement("binObj"); 
	binObj.dataType = 'bin.hex'; 
	binObj.nodeTypedValue = binStr; 
	return(String(binObj.text)); 

}

function GetFirebirdSPParameters(SPName) {
	var Dataset = SafeGetQueryData(connFirebird,
	'select\n'+
		'Trim(RDB$PARAMETER_NAME) as ParamName,\n'+
		'RDB$PARAMETER_TYPE as ParamType,\n'+
		'lower(Trim(Types.RDB$TYPE_NAME)) as TypeName,\n'+
		'lower(Trim(CharSet.RDB$CHARACTER_SET_NAME)) CharSet,\n'+
		'Fields.RDB$CHARACTER_LENGTH Len,\n'+
		'Fields.RDB$COLLATION_ID CollationID,\n'+
		'Fields.RDB$FIELD_PRECISION Precis,\n'+
		'Fields.RDB$DEFAULT_SOURCE DefValue\n'+
		'from rdb$procedure_parameters Params\n'+
		'inner join rdb$FIELDS Fields on Fields.rdb$field_name= Params.rdb$field_source\n'+
		'inner join rdb$TYPES Types on Types.rdb$TYPE= Fields.rdb$field_Type and Types.RDB$FIELD_NAME=\'RDB$FIELD_TYPE\'\n'+
		'left join rdb$CHARACTER_SETS CharSet on CharSet.rdb$CHARACTER_SET_ID= Fields.rdb$CHARACTER_SET_ID\n'+
		'where Params.RDB$PROCEDURE_NAME=\''+SPName+'\'\n'+
		'order by RDB$PARAMETER_TYPE,RDB$PARAMETER_NUMBER');
	var InputParams = '';
	var OutputParams = '';
	var NameField = Dataset.Fields('ParamName');
	var TypeField = Dataset.Fields('ParamType');
	var TypeNameField = Dataset.Fields('TypeName');
	var LenField = Dataset.Fields('Len');
	var CharSetField = Dataset.Fields('CharSet');
	var CollationIDField = Dataset.Fields('CollationID');
	var PrecisField = Dataset.Fields('Precis');
	var DefValueField = Dataset.Fields('DefValue');
	var DefValue;
	var ParamSQLText;
	while (!Dataset.EOF) {
		ParamSQLText = '    "'+Trim(NameField.Value)+'" ';
		switch (TypeNameField.Value) {
			case 'long':
				ParamSQLText+='integer';
				break;
			case 'varying':
				ParamSQLText+='varchar('+LenField.Value+')';
				if (CharSetField.Value && (CharSetField.Value != 'none')) {
					ParamSQLText+=' character set '+CharSetField.Value;
				}
				if (CollationIDField.Value) {
					ParamSQLText+=' collation '+CollationIDField.Value;
				}
				break;
			default:
				ParamSQLText+=TypeNameField.Value;
				if (PrecisField.Value) {
					ParamSQLText+=' precision '+PrecisField.Value;
				}
				break;
			
		}
		DefValue = DefValueField.Value;
		if (DefValue) {
			ParamSQLText+=' ' + DefValue;
		}
		if (TypeField.Value) {
			if (OutputParams) {
				OutputParams+=',\n';
			}
			OutputParams+=ParamSQLText;
		} else {
			if (InputParams) {
				InputParams+=',\n';
			}
			InputParams+=ParamSQLText;
		}
		Dataset.MoveNext();
	}
	var NameField = null;
	var TypeField = null;
	var LenField = null;
	var CharSetField = null;
	var CollationIDField = null;
	var PrecisField = null;
	return {Input :InputParams,
			Output :OutputParams};
}

function ExtractSP() {
	var Dataset = SafeGetQueryData(connFirebird, 'select RDB$PROCEDURE_NAME as SPName, RDB$PROCEDURE_SOURCE as SPText from RDB$PROCEDURES order by RDB$PROCEDURE_NAME');
	var RootScriptFolder = FSO.GetParentFolderName(WScript.ScriptFullName).replace(/\\$/,'')+'\\';
	ExportDataFileName = RootScriptFolder+'Out\\'+
			FSO.GetFileName(FirebirdDatabaseName).split('.')[0]+'.sql';
	Log('Exporting to: ' + ExportDataFileName);
	if (FSO.FileExists(ExportDataFileName)) {
			FSO.DeleteFile(ExportDataFileName, true);
	}
	var FileStream = FSO.CreateTextFile(ExportDataFileName, true, false);
	var SPTextField = Dataset.Fields('SPText');
	var SPNameField = Dataset.Fields('SPName');
	var SPParameters;
	while(!Dataset.EOF) {
		SPParameters = GetFirebirdSPParameters(SPNameField.Value);
		if (SPParameters.Input) {
			FileStream.WriteLine('CREATE OR ALTER PROCEDURE "'+Trim(SPNameField.Value)+'"(');
			FileStream.WriteLine(SPParameters.Input+')');
		} else {
			FileStream.WriteLine('CREATE OR ALTER PROCEDURE "'+Trim(SPNameField.Value)+'"');
		}
		if (SPParameters.Output) {
			FileStream.WriteLine('returns (\n'+SPParameters.Output+')');
		}
		FileStream.WriteLine('as');
		FileStream.WriteLine(SPTextField.Value);
		FileStream.WriteLine(';');
		Dataset.MoveNext();
	}
	FileStream.Close();
	FileStream = null;
	Dataset = null;
}

function Main() {
	Initialize();
	Connect();
	ExtractSP();
	Finalize();
}

Main()