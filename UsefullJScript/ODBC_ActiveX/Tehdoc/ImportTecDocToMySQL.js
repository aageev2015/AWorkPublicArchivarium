var RecordsLoggedInterval = 100000;
var ExportGraphicsDir = 'i:\\Work\\TecDoc\\Graphics\\';
var TecDocDataSource = 'TECDOC_CD_3_2010';
var QuitOnError = false;



var connMySQL = null;
var connTecDoc = null;
var connSupport = null;

var MySQLTecdocDatabaseName = 'Tecdoc3_2010';
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

function Initialize() {
	Log("Initializing");
	connMySQL = new ActiveXObject("ADODB.Connection");
	connTecDoc = new ActiveXObject("ADODB.Connection");
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
	CloseConnection(connTecDoc);
	CloseConnection(connMySQL);
	if(connSupport != null) {
		CloseConnection(connSupport);
	}
	WScript.StdOut.Write("Finished");
	connMySQL = null;
	connTecDoc = null;
	Stream = null;
	Shell = null;
	FSO = null;
	connSupport = null;
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
	Log("Connecting to MySQL");
	InitializeConnection(connMySQL, 
		"Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=" + MySQLTecdocDatabaseName + ";User=root;Password=1;Option=3;");
	Log("Connecting to TecDoc");
	InitializeConnection(connTecDoc,
		"Provider=MSDASQL.1;Password=tcd_error_0;Persist Security Info=True;User ID=tecdoc;Data Source=" + TecDocDataSource + ";Initial Catalog=" + TecDocDataSource);
}

function OpenSupportConnection() {
	Log("Initializing Support connection");
	connSupport = new ActiveXObject("ADODB.Connection");
	InitializeConnection(connSupport, 
		"Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=TecDocSupport;User=root;Password=1;Option=3;");
}


function DoQuit() {
	Finalize();
	WScript.Quit();
}

function GetTecDocTableRecordsCount(TableName) {
	if (TableName == 'mylog') {
		return ' table not exists';
	}
	if (TableName == 't_dual') {
		return ' table is faked';
	}
	var TecDocDataCount = SafeGetQueryData(connTecDoc, 
			'select count(*) from ' + TableName);
	if (IsErrorFlag) {
		return 'undefined';
	}
	var Count = TecDocDataCount.Fields(0).Value;
	TecDocDataCount = null;
	return Count;
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

function ShowAllTablesCount(IsSaveToMySQL) {
	Log('Start: Tables Count');
	var MySQLData = SafeGetQueryData(connMySQL, 
			'select table_name from information_schema.tables where table_schema=\'' + MySQLTecdocDatabaseName + '\'');
	if (IsErrorFlag) {
		MySQLData = null;
		return;
	}
	var TecDocDataCount;
	var TableName;
	var Count;
	var connMySQLSup;
/*	if (IsSaveToMySQL) {
		OpenSupportConnection();
	}*/
	while (!MySQLData.EOF) {
		TableName = MySQLData.fields(0).Value;
		Count = GetTecDocTableRecordsCount(TableName);
		if (IsErrorFlag) {
			if (QuitOnError) {
				MySQLData = null;
				DoQuit();
			}
			IsErrorFlag = false;
		} else {
			if (IsSaveToMySQL && (Count*1==Count)) {
				SafeExecuteQuery(connMySQL /*connSupport*/,
					'update TecDocSupport.tbl_tablesdescription set TecDocCount= ' + Count + ' where Table_Name = \'' + TableName + '\'');
				if (IsErrorFlag) {
					IsErrorFlag = false;
				}
			}
			Log('		' + TableName + '.RecordsCount:		' + Count);
		}
		MySQLData.MoveNext();
	}
	MySQLData = null;
	Log('Finish: Tables Count');
}

function SaveGraphicIntoFiles(TableNumber) {
	var IDFieldName = 'GRD_ID';
	var BlobFieldName = 'GRD_GRAPHIC';
	var ExtensionFieldName = 'DOC_EXTENSION';
	var TableName = 'tof_gra_data_' + TableNumber;
	var SelectQueryText = 
			'select ' + IDFieldName + ', ' + BlobFieldName + ', ' + ExtensionFieldName + ' ' +
			'from ' + TableName + ' ' +
			'inner join tof_graphics on ' +
			'	GRA_TAB_NR=' + TableNumber + ' ' +
			'	and GRA_GRD_ID = GRD_ID ' +
			'	inner join tof_doc_Types on ' +
			'	GRA_DOC_TYPE = Doc_Type ';
	var WasError = false;
	try {
		var TecDocData = connTecDoc.Execute(SelectQueryText);
	} catch(e) {
		Log('	Select error: ' + e.message);
		WasError = true;
	}
	if (WasError) {
		TecDocData = null;
		if (QuitOnError) {
			DoQuit();
		}
		return;
	}
	Stream.Type = adTypeBinary;
	var FileName;
	var ID;
	var Extension;
	var RowCount = 0;
	var Fields = TecDocData.Fields;
	var ExportFileName;
	var ExportDir = ExportGraphicsDir + TableName + '\\';
	if (!FSO.FolderExists(ExportDir)) {
		FSO.CreateFolder(ExportDir);
	}
	while (!TecDocData.EOF) {
		ID = Fields(IDFieldName).Value
		Extension = Fields(ExtensionFieldName).Value
		ExportFileName = ExportDir + TableName + '_' + ID + '.';
		try {
			Stream.Open();
			Stream.Write(Fields(BlobFieldName).Value);
			if (FSO.FileExists(ExportFileName)) {
				FSO.DeleteFile(ExportFileName, true);
			}
			Stream.SaveToFile(ExportFileName + Extension);
			Stream.Close();
			if (Extension == 'JP2') {
				Shell.Run('img2img.exe ' + ExportFileName + Extension + ' ' + ExportFileName + 'jpg', 0, 1);
				FSO.DeleteFile(ExportFileName + Extension);
			}
		} catch(e) {
			Log('	Export blob error: ' + e.message);
			WasError = true;

		}
		if (WasError) {
			if (QuitOnError) {
				TecDocData.Close();
				TecDocData = null;
				DoQuit();
			}
		}		
		wasError = false;
		TecDocData.MoveNext();
		RowCount++
		if (RowCount%RecordsLoggedInterval == 0) {
			Log('		'+ TableName + ':	' + RowCount);
		}

	}
	TecDocData.Close();
	TecDocData = null;
	Log('End Export Graphics ' + TableName + '.' + IDFieldName + '\\' + BlobFieldName +': ' + RowCount + ' rows total');

}

//This make truncate tables before import
function ImportTable_MySQL_to_Tecdoc(TableName) {
	Log('***Begin*** import ' + TableName + '	at  '+ DateTimeToStr(new Date()));
	var TimerCode = 'import';
	ClearTimer(TimerCode);
	StartTimer(TimerCode);
	var objRecordset;
	var ColumnList = '';
	for (var i = 1; i < arguments.length;i++){
		if (ColumnList.length != 0){
			ColumnList += ', ';
		}
		ColumnList += arguments[i];
		
	}
	var TecDocData = SafeGetQueryData(connTecDoc, 
			'select ' + ColumnList + ' from ' + TableName);
	if (IsErrorFlag) {
		if (QuitOnError) {
			TecDocData = null;
			DoQuit();
		}
		IsErrorFlag = false;
	}
	Log('		Selecting time: ' + GetTimerValueAsStr(TimerCode))
	var MySQLColumns = '';
	var i;
	var Fields = TecDocData.Fields;
	var FieldsCount = Fields.Count;
	for (i=0; i<FieldsCount; i++) {
		if (MySQLColumns) {
			MySQLColumns += ', ';
		}
		MySQLColumns += Fields(i).Name;
	}
	var InsertPrefix = 'insert into ' + TableName + '('+MySQLColumns+') values( ' ;
	var FieldValuesText;
	
	var RowCount = 1;
	
	var FieldType;
	connMySQL.Execute('truncate ' + TableName);
	while (!TecDocData.EOF) {
		FieldValuesText = '';
		for (i=0; i < FieldsCount; i++) {
			if (FieldValuesText.length != 0){
				FieldValuesText += ', ';
			}
			if (Fields(i).Value == null) {
				FieldValuesText += 'NULL';
			} else	{
				FieldType = Fields(i).Type;
				if ((FieldType == 3) || (FieldType == 2)) {
					FieldValuesText += Fields(i).Value;
				} else {
					if ((FieldType != 200) && (FieldType != 129)) {
						FieldValuesText += '\'' + Fields(i).Value + '\'';
					} else {
						FieldValuesText += '\'' + 
						Fields(i).Value.
							replace(/\\/g,'\\\\').
							replace(/"/g,'\\"').
							replace(/\'/g,'\\\'')
							 + '\'';
					}
				}
			}
		}
		SafeExecuteQuery(connMySQL, 
				InsertPrefix + FieldValuesText + ')');
		if (IsErrorFlag) {
			if (QuitOnError) {
				TecDocData.Close();
				TecDocData = null;
				DoQuit();
			}
			IsErrorFlag = false;
		}
		TecDocData.MoveNext();
		RowCount++
		if (RowCount % RecordsLoggedInterval == 0) {
			Log('			'+ TableName + ':	' + RowCount + '		timer: ' + GetTimerValueAsStr(TimerCode));
		}
	}
	TecDocData.Close();
	TecDocData = null;
	Log(DateTimeToStr(new Date()));
	Log('End import ' + TableName + ': 		' + RowCount + ' rows total;		Total Time: ' + GetTimerValueAsStr(TimerCode) + '	avg: ' + MillisecondsToReadableText(GetTimerValue(TimerCode)/RowCount*RecordsLoggedInterval));
	Log('');
	ClearTimer(TimerCode);
}

function ImportForm_MySQL_to_Tecdoc() {
/*
+ - закачана полностью без ошибок, проверено количество залитых записей
0 - таблица пустая в текдоке
errored\Waiting и др - недокачано, была ошибка, или слишком большая, нужно много времени
+- - свала не было, но количество не совпало.
*/

//ImportTable_MySQL_to_Tecdoc('t_dual', 'A');
//+ImportTable_MySQL_to_Tecdoc('tof_accessory_lists', 'ACL_ART_ID', 'ACL_NR', 'ACL_SORT', 'ACL_LINK_TYPE', 'ACL_MFA_ID', 'ACL_MOD_ID', 'ACL_TYP_ID', 'ACL_ENG_ID', 'ACL_ACCESSORY_ART_ID', 'ACL_QUANTITY', 'ACL_GA_ID', 'ACL_CTM', 'ACL_DES_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_acl_country_quantities', 'ACCQ_ART_ID', 'ACCQ_NR', 'ACCQ_SORT', 'ACCQ_CTM', 'ACCQ_QUANTITY');
//+ImportTable_MySQL_to_Tecdoc('tof_acl_criteria', 'ACC_ART_ID', 'ACC_NR', 'ACC_SORT', 'ACC_SEQ_NR', 'ACC_CRI_ID', 'ACC_VALUE', 'ACC_KV_DES_ID', 'ACC_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_ali_coordinates', 'ACO_GRA_ID', 'ACO_GRA_LNG_ID', 'ACO_ALI_ART_ID', 'ACO_ALI_SORT', 'ACO_SORT', 'ACO_TYPE', 'ACO_X1', 'ACO_Y1', 'ACO_X2', 'ACO_Y2');
//0ImportTable_MySQL_to_Tecdoc('tof_ali_country_quantities', 'ACQ_ALI_ART_ID', 'ACQ_ALI_SORT', 'ACQ_QUANTITY', 'ACQ_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_art_country_specifics', 'ACS_ART_ID', 'ACS_CTM', 'ACS_PACK_UNIT', 'ACS_QUANTITY_PER_UNIT', 'ACS_KV_STATUS_DES_ID', 'ACS_KV_STATUS'/*, 'ACS_STATUS_DATE'*/);
//+ImportTable_MySQL_to_Tecdoc('tof_art_lookup', 'ARL_ART_ID', 'ARL_SEARCH_NUMBER', 'ARL_KIND', 'ARL_CTM', 'ARL_BRA_ID', 'ARL_DISPLAY_NR', 'ARL_DISPLAY', 'ARL_BLOCK', 'ARL_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_article_criteria', 'ACR_ART_ID', 'ACR_GA_ID', 'ACR_SORT', 'ACR_CRI_ID', 'ACR_VALUE', 'ACR_KV_DES_ID', 'ACR_CTM', 'ACR_DISPLAY');
//+ImportTable_MySQL_to_Tecdoc('tof_article_info', 'AIN_ART_ID', 'AIN_GA_ID', 'AIN_SORT', 'AIN_CTM', 'AIN_KV_TYPE', 'AIN_DISPLAY', 'AIN_TMO_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_article_list_criteria', 'ALC_ALI_ART_ID', 'ALC_ALI_SORT', 'ALC_CTM', 'ALC_SORT', 'ALC_CRI_ID', 'ALC_VALUE', 'ALC_KV_DES_ID', 'ALC_TYP_ID', 'ALC_ENG_ID', 'ALC_AXL_ID', 'ALC_MRK_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_article_lists', 'ALI_ART_ID', 'ALI_SORT', 'ALI_ART_ID_COMPONENT', 'ALI_QUANTITY', 'ALI_CTM', 'ALI_GA_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_article_user_notes', 'AUN_ART_ID', 'AUN_KIND', 'AUN_ENG_ID', 'AUN_TYP_ID', 'AUN_AXL_ID', 'AUN_MRK_ID', 'AUN_TEXT', 'AUN_USS_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_article_user_notes_imp', 'AUN_KIND', 'AUN_ENG_ID', 'AUN_TYP_ID', 'AUN_AXL_ID', 'AUN_MRK_ID', 'AUN_TEXT', 'AUN_USS_ID', 'AUN_ART_ARTICLE_NR', 'AUN_SUP_SUPPLIER_NR');
//+ImportTable_MySQL_to_Tecdoc('tof_articles', 'ART_ID', 'ART_ARTICLE_NR', 'ART_SUP_ID', 'ART_DES_ID', 'ART_COMPLETE_DES_ID', 'ART_CTM', 'ART_PACK_SELFSERVICE', 'ART_MATERIAL_MARK', 'ART_REPLACEMENT', 'ART_ACCESSORY', 'ART_BATCH_SIZE1', 'ART_BATCH_SIZE2');
//+ImportTable_MySQL_to_Tecdoc('tof_articles_new', 'ARTN_SUP_ID', 'ARTN_ART_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_axl_brake_sizes', 'ABS_AXL_ID', 'ABS_SORT', 'ABS_KV_BRAKE_SIZE_DES_ID', 'ABS_DESCRIPTION');
//0ImportTable_MySQL_to_Tecdoc('tof_axl_wheel_bases', 'AWB_AXL_ID', 'AWB_NR', 'AWB_KV_AXLE_POS_DES_ID', 'AWB_WHEEL_BASE');
//+ImportTable_MySQL_to_Tecdoc('tof_axles', 'AXL_ID', 'AXL_DESCRIPTION', 'AXL_SEARCH_TEXT', 'AXL_MMA_CDS_ID', 'AXL_MOD_ID', 'AXL_SORT', 'AXL_PCON_START', 'AXL_PCON_END', 'AXL_KV_TYPE_DES_ID', 'AXL_KV_STYLE_DES_ID', 'AXL_KV_BRAKE_TYPE_DES_ID', 'AXL_KV_BODY_DES_ID', 'AXL_LOAD_FROM', 'AXL_LOAD_UPTO', 'AXL_KV_WHEEL_MOUNT_DES_ID', 'AXL_TRACK_GAUGE', 'AXL_HUB_SYSTEM', 'AXL_DISTANCE_FROM', 'AXL_DISTANCE_UPTO', 'AXL_SEARCH_BRAKE_SIZES', 'AXL_LA_CTM');
//0ImportTable_MySQL_to_Tecdoc('tof_axles_histories', 'AHI_USS_ID', 'AHI_AXL_ID', 'AHI_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_brands', 'BRA_ID', 'BRA_MFC_CODE', 'BRA_BRAND', 'BRA_MF_NR');
//0ImportTable_MySQL_to_Tecdoc('tof_cab_country_specifics', 'CAC_CAB_ID', 'CAC_COU_ID', 'CAC_KV_SIZE_DES_ID', 'CAC_PCON_START', 'CAC_PCON_END', 'X_CAC_DESIGN', 'X_CAC_LENGTH', 'X_CAC_HEIGHT', 'X_CAC_WIDTH');
//ImportTable_MySQL_to_Tecdoc('tof_connections', 'TOC_CONNECTION', 'TOC_TIMESTAMP');
//+ImportTable_MySQL_to_Tecdoc('tof_const_pattern_lookup', 'CPL_ID', 'CPL_CTM', 'CPL_SORT', 'CPL_ORIGINAL_TEXT', 'CPL_SEARCH_TEXT', 'CPL_KIND');
//+ImportTable_MySQL_to_Tecdoc('tof_countries', 'COU_ID', 'COU_CC', 'COU_DES_ID', 'COU_CTM', 'COU_CURRENCY_CODE', 'COU_ISO2', 'COU_IS_GROUP');
//+ImportTable_MySQL_to_Tecdoc('tof_country_designations', 'CDS_ID', 'CDS_CTM', 'CDS_LNG_ID', 'CDS_TEX_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_criteria', 'CRI_ID', 'CRI_DES_ID', 'CRI_SHORT_DES_ID', 'CRI_UNIT_DES_ID', 'CRI_TYPE', 'CRI_KT_ID', 'CRI_IS_INTERVAL', 'CRI_SUCCESSOR');
//+ImportTable_MySQL_to_Tecdoc('tof_cv_cabs', 'CAB_ID', 'CAB_MOD_ID', 'CAB_CDS_ID', 'CAB_MMC_CDS_ID', 'CAB_KV_SIZE_DES_ID', 'CAB_PCON_START', 'CAB_PCON_END', 'CAB_CTM', 'X_CAB_DESIGN', 'X_CAB_LENGTH', 'X_CAB_HEIGHT', 'X_CAB_WIDTH');
//+ImportTable_MySQL_to_Tecdoc('tof_cv_marks', 'MRK_ID', 'MRK_DESIGNATION', 'MRK_SEARCH_TEXT', 'MRK_MFA_ID', 'MRK_CTM', 'MRK_LA_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_cv_secondary_types', 'CST_TYP_ID', 'CST_SUBNR', 'CST_SORT', 'CST_CDS_ID', 'CST_PCON_START', 'CST_PCON_END', 'CST_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_des_texts', 'TEX_ID', 'TEX_TEXT');
/*'REPLACE(0xc39c CAST CHAR(*) BY \'U\' IN ' +
'  (  '+
'    REPLACE(0xc38b CAST CHAR(*) BY \'E\' IN '+
'      ('+
'        REPLACE(0xc396 CAST CHAR(*) BY \'O\' IN TEX_TEXT) '+
'      ) '+
'    ) '+
'  ) '+
') as TEX_TEXT'*/
//+ImportTable_MySQL_to_Tecdoc('tof_designations', 'DES_ID', 'DES_LNG_ID', 'DES_TEX_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_doc_types', 'DOC_TYPE', 'DOC_EXTENSION');
//+ImportTable_MySQL_to_Tecdoc('tof_eng_country_specifics', 'ENC_ENG_ID', 'ENC_COU_ID', 'ENC_PCON_START', 'ENC_PCON_END', 'ENC_KW_FROM', 'ENC_KW_UPTO', 'ENC_HP_FROM', 'ENC_HP_UPTO', 'ENC_VALVES', 'ENC_CYLINDERS', 'ENC_CCM_FROM', 'ENC_CCM_UPTO', 'ENC_KV_DESIGN_DES_ID', 'ENC_KV_FUEL_TYPE_DES_ID', 'ENC_KV_FUEL_SUPPLY_DES_ID', 'ENC_DESCRIPTION', 'ENC_KV_ENGINE_DES_ID', 'ENC_KW_RPM_FROM', 'ENC_KW_RPM_UPTO', 'ENC_TORQUE_FROM', 'ENC_TORQUE_UPTO', 'ENC_TORQUE_RPM_FROM', 'ENC_TORQUE_RPM_UPTO', 'ENC_COMPRESSION_FROM', 'ENC_COMPRESSION_UPTO', 'ENC_DRILLING', 'ENC_EXTENSION', 'ENC_CRANKSHAFT', 'ENC_KV_CHARGE_DES_ID', 'ENC_KV_GAS_NORM_DES_ID', 'ENC_KV_CYLINDERS_DES_ID', 'ENC_KV_CONTROL_DES_ID', 'ENC_KV_VALVE_CONTROL_DES_ID', 'ENC_KV_COOLING_DES_ID', 'ENC_CCM_TAX_FROM', 'ENC_CCM_TAX_UPTO', 'ENC_LITRES_TAX_FROM', 'ENC_LITRES_TAX_UPTO', 'ENC_LITRES_FROM', 'ENC_LITRES_UPTO', 'ENC_KV_USE_DES_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_eng_lookup', 'ENL_ENG_ID', 'ENL_SEARCH_TEXT', 'ENL_CTM');
//0ImportTable_MySQL_to_Tecdoc('tof_engine_histories', 'EHI_USS_ID', 'EHI_ENG_ID', 'EHI_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_engines', 'ENG_ID', 'ENG_MFA_ID', 'ENG_CODE', 'ENG_PCON_START', 'ENG_PCON_END', 'ENG_KW_FROM', 'ENG_KW_UPTO', 'ENG_HP_FROM', 'ENG_HP_UPTO', 'ENG_VALVES', 'ENG_CYLINDERS', 'ENG_CCM_FROM', 'ENG_CCM_UPTO', 'ENG_KV_DESIGN_DES_ID', 'ENG_KV_FUEL_TYPE_DES_ID', 'ENG_KV_FUEL_SUPPLY_DES_ID', 'ENG_CTM', 'ENG_LA_CTM', 'ENG_DESCRIPTION', 'ENG_KV_ENGINE_DES_ID', 'ENG_KW_RPM_FROM', 'ENG_KW_RPM_UPTO', 'ENG_TORQUE_FROM', 'ENG_TORQUE_UPTO', 'ENG_TORQUE_RPM_FROM', 'ENG_TORQUE_RPM_UPTO', 'ENG_COMPRESSION_FROM', 'ENG_COMPRESSION_UPTO', 'ENG_DRILLING', 'ENG_EXTENSION', 'ENG_CRANKSHAFT', 'ENG_KV_CHARGE_DES_ID', 'ENG_KV_GAS_NORM_DES_ID', 'ENG_KV_CYLINDERS_DES_ID', 'ENG_KV_CONTROL_DES_ID', 'ENG_KV_VALVE_CONTROL_DES_ID', 'ENG_KV_COOLING_DES_ID', 'ENG_CCM_TAX_FROM', 'ENG_CCM_TAX_UPTO', 'ENG_LITRES_TAX_FROM', 'ENG_LITRES_TAX_UPTO', 'ENG_LITRES_FROM', 'ENG_LITRES_UPTO', 'ENG_KV_USE_DES_ID');
//ImportTable_MySQL_to_Tecdoc('tof_err_track_key_values', 'ETK_TAB_NR', 'ETK_KEY', 'ETK_LNG_ID', 'ETK_SORTNR', 'ETK_DESCRIPTION');
//ImportTable_MySQL_to_Tecdoc('tof_filters', 'FIL_USS_ID', 'FIL_KIND', 'FIL_VALUE');
//+ImportTable_MySQL_to_Tecdoc('tof_generic_articles', 'GA_ID', 'GA_NR', 'GA_DES_ID', 'GA_DES_ID_STANDARD', 'GA_DES_ID_ASSEMBLY', 'GA_DES_ID_INTENDED', 'GA_UNIVERSAL');
//0ImportTable_MySQL_to_Tecdoc('tof_gra_data_0', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_1', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_10', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_11', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_12', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_13', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_14', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_15', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_16', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_17', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_18', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_19', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_2', 'GRD_ID', 'GRD_GRAPHIC');
//SaveGraphicIntoFiles(2);
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_20', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_21', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_22', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_23', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_24', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_25', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_26', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_27', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_28', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_29', 'GRD_ID', 'GRD_GRAPHIC');
//0ImportTable_MySQL_to_Tecdoc('tof_gra_data_3', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_30', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_4', 'GRD_ID', 'GRD_GRAPHIC');
//SaveGraphicIntoFiles(4);
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_5', 'GRD_ID', 'GRD_GRAPHIC');
//SaveGraphicIntoFiles(5);
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_6', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_7', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_8', 'GRD_ID', 'GRD_GRAPHIC');
//ImportTable_MySQL_to_Tecdoc('tof_gra_data_9', 'GRD_ID', 'GRD_GRAPHIC');
//+ImportTable_MySQL_to_Tecdoc('tof_graphics', 'GRA_SUP_ID', 'GRA_ID', 'GRA_DOC_TYPE', 'GRA_LNG_ID', 'GRA_GRD_ID', 'GRA_TYPE', 'GRA_NORM', 'GRA_SUPPLIER_NR', 'GRA_TAB_NR', 'GRA_DES_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_help_mappings', 'HLP_TOPIC', 'HLP_FILE', 'HLP_NOTICE');
//+ImportTable_MySQL_to_Tecdoc('tof_key_values', 'KV_KT_ID', 'KV_KV', 'KV_DES_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_la_criteria', 'LAC_LA_ID', 'LAC_SORT', 'LAC_CRI_ID', 'LAC_VALUE', 'LAC_KV_DES_ID', 'LAC_CTM', 'LAC_DISPLAY');
//+ImportTable_MySQL_to_Tecdoc('tof_la_info', 'LIN_LA_ID', 'LIN_SORT', 'LIN_CTM', 'LIN_KV_TYPE', 'LIN_DISPLAY', 'LIN_TMO_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_languages', 'LNG_ID', 'LNG_DES_ID', 'LNG_ISO2', 'LNG_CODEPAGE');
//+ImportTable_MySQL_to_Tecdoc('tof_link_art', 'LA_ID', 'LA_ART_ID', 'LA_GA_ID', 'LA_CTM', 'LA_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_art_ga', 'LAG_ART_ID', 'LAG_GA_ID', 'LAG_SUP_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_link_cab_typ', 'LCT_TYP_ID', 'LCT_NR', 'LCT_CAB_ID', 'LCT_PCON_START', 'LCT_PCON_END', 'LCT_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_link_ga_cri', 'LGC_GA_NR', 'LGC_CRI_ID', 'LGC_CTM', 'LGC_SORT', 'LGC_SUGGESTION');
//+ImportTable_MySQL_to_Tecdoc('tof_link_ga_str', 'LGS_STR_ID', 'LGS_GA_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_link_gra_art', 'LGA_ART_ID', 'LGA_SORT', 'LGA_CTM', 'LGA_GRA_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_link_gra_la', 'LGL_LA_ID', 'LGL_TYP_ID', 'LGL_ENG_ID', 'LGL_AXL_ID', 'LGL_MRK_ID', 'LGL_SORT', 'LGL_CTM', 'LGL_GRA_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_axl', 'LAA_LA_ID', 'LAA_AXL_ID', 'LAA_GA_ID', 'LAA_CTM', 'LAA_SUP_ID', 'LAA_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_axl_new', 'LAAN_LA_ID', 'LAAN_AXL_ID', 'LAAN_GA_ID', 'LAAN_CTM', 'LAAN_SUP_ID', 'LAAN_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_eng', 'LAE_LA_ID', 'LAE_ENG_ID', 'LAE_GA_ID', 'LAE_CTM', 'LAE_SUP_ID', 'LAE_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_eng_new', 'LAEN_SUP_ID', 'LAEN_GA_ID', 'LAEN_LA_ID', 'LAEN_ENG_ID', 'LAEN_CTM', 'LAEN_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_mrk', 'LAM_LA_ID', 'LAM_MRK_ID', 'LAM_GA_ID', 'LAM_CTM', 'LAM_SUP_ID', 'LAM_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_mrk_new', 'LAMN_LA_ID', 'LAMN_MRK_ID', 'LAMN_GA_ID', 'LAMN_CTM', 'LAMN_SUP_ID', 'LAMN_SORT');
ImportTable_MySQL_to_Tecdoc('tof_link_la_typ', 'LAT_TYP_ID', 'LAT_LA_ID', 'LAT_GA_ID', 'LAT_CTM', 'LAT_SUP_ID', 'LAT_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_la_typ_new', 'LATN_SUP_ID', 'LATN_GA_ID', 'LATN_TYP_ID', 'LATN_LA_ID', 'LATN_CTM', 'LATN_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_sho_str', 'LSS_SHO_ID', 'LSS_STR_ID', 'LSS_EXPAND', 'LSS_LEVEL', 'LSS_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_link_sho_str_type', 'LST_STR_TYPE', 'LST_SHO_ID', 'LST_SORT');
//0ImportTable_MySQL_to_Tecdoc('tof_link_typ_axl', 'LTA_TYP_ID', 'LTA_SORT', 'LTA_AXL_ID', 'LTA_PCON_START', 'LTA_PCON_END', 'LTA_CTM', 'LTA_KV_AXLE_POS_DES_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_link_typ_eng', 'LTE_TYP_ID', 'LTE_NR', 'LTE_ENG_ID', 'LTE_PCON_START', 'LTE_PCON_END', 'LTE_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_link_typ_mrk', 'LMK_TYP_ID', 'LMK_MRK_ID', 'LMK_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_manufacturers', 'MFA_ID', 'MFA_PC_MFC', 'MFA_CV_MFC', 'MFA_AXL_MFC', 'MFA_ENG_MFC', 'MFA_ENG_TYP', 'MFA_MFC_CODE', 'MFA_BRAND', 'MFA_MF_NR', 'MFA_PC_CTM', 'MFA_CV_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_mod_typ_lookup', 'MTL_TYP_ID', 'MTL_CTM', 'MTL_LNG_ID', 'MTL_SEARCH_TEXT');
//+ImportTable_MySQL_to_Tecdoc('tof_models', 'MOD_ID', 'MOD_MFA_ID', 'MOD_CDS_ID', 'MOD_PCON_START', 'MOD_PCON_END', 'MOD_PC', 'MOD_CV', 'MOD_AXL', 'MOD_PC_CTM', 'MOD_CV_CTM');
//0ImportTable_MySQL_to_Tecdoc('tof_natcodes_austria', 'NCA_NATCODE', 'NCA_TYP_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_natcodes_ch', 'NCH_NATCODE', 'NCH_TYP_ID');
//ImportTable_MySQL_to_Tecdoc('tof_numberplates_nl', 'NNL_NUMBERPLATE', 'NNL_TYP_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_numberplates_s', 'NSW_NUMBERPLATE', 'NSW_TYP_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_parameters', 'PAR_NAME', 'PAR_VALUE');
//ImportTable_MySQL_to_Tecdoc('tof_prices', 'PRI_ART_ID', 'PRI_KV_PRICE_TYPE', 'PRI_CTM', 'PRI_PRICE', 'PRI_KV_PRICE_UNIT_DES_ID', 'PRI_KV_QUANTITY_UNIT_DES_ID', 'PRI_VAL_START', 'PRI_VAL_END', 'PRI_CURRENCY_CODE', 'PRI_REBATE', 'PRI_DISCOUNT_FLAG');
//ImportTable_MySQL_to_Tecdoc('tof_prices_import', 'PRII_ARTICLE_NR', 'PRII_SUPPLIER_NR', 'PRII_KV_PRICE_TYPE', 'PRII_CC', 'PRII_PRICE', 'PRII_KV_PRICE_UNIT', 'PRII_KV_QUANTITY_UNIT', 'PRII_VAL_START', 'PRII_VAL_END', 'PRII_CURRENCY_CODE', 'PRII_REBATE', 'PRII_ART_ID', 'PRII_CTM', 'PRII_KV_PRICE_UNIT_DES_ID', 'PRII_KV_QUANTITY_UNIT_DES_ID', 'PRII_DISCOUNT_FLAG');
//ImportTable_MySQL_to_Tecdoc('tof_retail_filter_import', 'TRF_TSD_ID', 'TRF_GA_NR', 'TRF_SUPPLIER_NR', 'TRF_ABC', 'TRF_SORT');
//ImportTable_MySQL_to_Tecdoc('tof_retail_filters', 'TRF_TSD_ID', 'TRF_GA_ID', 'TRF_SUP_ID', 'TRF_ABC', 'TRF_SORT');
//ImportTable_MySQL_to_Tecdoc('tof_search_histories', 'SHI_USS_ID', 'SHI_KIND', 'SHI_SEARCH_TEXT', 'SHI_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_search_tree', 'STR_ID', 'STR_ID_PARENT', 'STR_TYPE', 'STR_LEVEL', 'STR_DES_ID', 'STR_SORT', 'STR_NODE_NR');
//ImportTable_MySQL_to_Tecdoc('tof_search_tree_filters', 'STF_USS_ID', 'STF_STR_ID', 'STF_STR_NODE_NR');
//0ImportTable_MySQL_to_Tecdoc('tof_shopping_basket_audacon', 'SAU_USS_ID', 'SAU_TYP_ID', 'SAU_KIND', 'SAU_POS_NR', 'SAU_AUDACON_TYPE_ID', 'SAU_BODY_ID_LT', 'SAU_BODY_ID_MD', 'SAU_WORK_ID', 'SAU_EXCLUSIVE_ID', 'SAU_CALCULATED', 'SAU_VAT_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_shopping_baskets', 'SBA_USS_ID', 'SBA_ART_ID', 'SBA_SORT', 'SBA_QUANTITY', 'SBA_CONTEXT_SECTION', 'SBA_TYP_ID', 'SBA_ENG_ID', 'SBA_AXL_ID', 'SBA_MRK_ID', 'SBA_GA_ID', 'SBA_TSD_ID', 'SBA_PRICE_PURCHASE', 'SBA_KV_PT', 'SBA_KV_PU_DES_ID_PURCHASE', 'SBA_KV_QU_DES_ID_PURCHASE', 'SBA_PRICE_OFFER', 'SBA_KV_PU_DES_ID_OFFER', 'SBA_KV_QU_DES_ID_OFFER', 'SBA_PRICE_INVOICE', 'SBA_KV_PU_DES_ID_INVOICE', 'SBA_KV_QU_DES_ID_INVOICE', 'SBA_TSP_PRICE_PURCHASE', 'SBA_TSP_KV_PT_PURCHASE', 'SBA_TSP_KV_PU_DES_ID_PURCHASE', 'SBA_TSP_KV_QU_DES_ID_PURCHASE', 'SBA_TSP_PRICE_OFFER', 'SBA_TSP_KV_PT_OFFER', 'SBA_TSP_KV_PU_DES_ID_OFFER', 'SBA_TSP_KV_QU_DES_ID_OFFER', 'SBA_TSP_PRICE_INVOICE', 'SBA_TSP_KV_PT_INVOICE', 'SBA_TSP_KV_PU_DES_ID_INVOICE', 'SBA_TSP_KV_QU_DES_ID_INVOICE', 'SBA_EINSPEISER_NR', 'SBA_ARTICLE_NR', 'SBA_COU_ID_CAR_DDDW', 'SBA_COU_ID_CAR_DES', 'SBA_TAX_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_shopping_lists', 'SLI_USS_ID', 'SLI_ART_ID', 'SLI_SORT', 'SLI_CONTEXT_SECTION', 'SLI_TYP_ID', 'SLI_ENG_ID', 'SLI_AXL_ID', 'SLI_MRK_ID', 'SLI_GA_ID', 'SLI_TSD_ID', 'SLI_COU_ID_CAR_DDDW', 'SLI_COU_ID_CAR_DES');
//0ImportTable_MySQL_to_Tecdoc('tof_shopping_lists_imp', 'SLI_USS_ID', 'SLI_SORT', 'SLI_CONTEXT_SECTION', 'SLI_TYP_ID', 'SLI_ENG_ID', 'SLI_AXL_ID', 'SLI_MRK_ID', 'SLI_GA_ID', 'SLI_TSD_ID', 'SLI_ART_ARTICLE_NR', 'SLI_SUP_SUPPLIER_NR', 'SLI_COU_ID_CAR_DDDW', 'SLI_COU_ID_CAR_DES');
//+ImportTable_MySQL_to_Tecdoc('tof_shortcuts', 'SHO_ID', 'SHO_DES_ID', 'SHO_PICTURE');
//+ImportTable_MySQL_to_Tecdoc('tof_str_family_tree', 'SFT_ANCESTOR_STR_ID', 'SFT_DESCENDANT_STR_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_str_lookup', 'STL_LNG_ID', 'STL_SEARCH_TEXT', 'STL_STR_ID', 'STL_GA_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_superseded_articles', 'SUA_ART_ID', 'SUA_CTM', 'SUA_NUMBER', 'SUA_SORT');
//+ImportTable_MySQL_to_Tecdoc('tof_supplier_addresses', 'SAD_SUP_ID', 'SAD_TYPE_OF_ADDRESS', 'SAD_COU_ID', 'SAD_NAME1', 'SAD_NAME2', 'SAD_STREET1', 'SAD_STREET2', 'SAD_POB', 'SAD_COU_ID_POSTAL', 'SAD_POSTAL_CODE_PLACE', 'SAD_POSTAL_CODE_POB', 'SAD_POSTAL_CODE_CUST', 'SAD_CITY1', 'SAD_CITY2', 'SAD_TEL', 'SAD_FAX', 'SAD_EMAIL', 'SAD_WEB');
//+ImportTable_MySQL_to_Tecdoc('tof_supplier_logos', 'SLO_SUP_ID', 'SLO_CTM', 'SLO_LNG_ID', 'SLO_LOGO');
//+ImportTable_MySQL_to_Tecdoc('tof_suppliers', 'SUP_ID', 'SUP_BRAND', 'SUP_SUPPLIER_NR', 'SUP_COU_ID', 'SUP_IS_HESS');
//0ImportTable_MySQL_to_Tecdoc('tof_suppressed_messages', 'SUM_USS_ID', 'SUM_MESSAGE_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_tecsel_dealers', 'TSD_ID', 'TSD_DATE', 'TSD_MATCHCODE', 'TSD_NAME', 'TSD_STREET', 'TSD_CITY', 'TSD_POSTAL_CODE', 'TSD_POB', 'TSD_POSTAL_CODE_POB', 'TSD_CC_POSTAL', 'TSD_PHONE', 'TSD_PHONE_MOBILE', 'TSD_FAX', 'TSD_CDID', 'TSD_DEALER_CUSTOMER', 'TSD_ADDRESS', 'TSD_DEALER_CUSTOMER_NUMBER', 'TSD_RETAIL_FILTER', 'TSD_FILTER_DELETABLE', 'TSD_EMAIL', 'TSD_DEALER_CUSTOMER_NR');
//0ImportTable_MySQL_to_Tecdoc('tof_tecsel_link_user_sale', 'TSL_TSS_TSD_ID', 'TSL_TSS_NAME', 'TSL_USS_ID');
//0ImportTable_MySQL_to_Tecdoc('tof_tecsel_price_import', 'TSPI_TSD_ID', 'TSPI_ARTICLE_NR', 'TSPI_SUPPLIER_NR', 'TSPI_CC', 'TSPI_EVK', 'TSPI_KV_PRICE_TYPE', 'TSPI_KV_PRICE_UNIT', 'TSPI_VAL_START', 'TSPI_VAL_END', 'TSPI_PRICE', 'TSPI_KV_QUANTITY_UNIT', 'TSPI_AVAILABILITY', 'TSPI_REBATE', 'TSPI_CURRENCY_CODE', 'TSPI_ART_ID', 'TSPI_CTM', 'TSPI_KV_PRICE_UNIT_DES_ID', 'TSPI_KV_QUANTITY_UNIT_DES_ID', 'TSPI_DEALER_ARTICLE_NR');
//0ImportTable_MySQL_to_Tecdoc('tof_tecsel_prices', 'TSP_TSD_ID', 'TSP_ART_ID', 'TSP_CTM', 'TSP_EVK', 'TSP_KV_PRICE_TYPE', 'TSP_KV_PRICE_UNIT_DES_ID', 'TSP_KV_QUANTITY_UNIT_DES_ID', 'TSP_VAL_START', 'TSP_VAL_END', 'TSP_PRICE', 'TSP_CURRENCY_CODE', 'TSP_AVAILABILITY', 'TSP_REBATE', 'TSP_DEALER_ARTICLE_NR', 'TSP_SEARCH_NUMBER');
//0ImportTable_MySQL_to_Tecdoc('tof_tecsel_sale_addresses', 'TSS_TSD_ID', 'TSS_NAME', 'TSS_DEALER_NR', 'TSS_COMPANY_NAME', 'TSS_STREET', 'TSS_CITY', 'TSS_POSTAL_CODE', 'TSS_POB', 'TSS_POSTAL_CODE_POB', 'TSS_CC_POSTAL', 'TSS_PHONE', 'TSS_PHONE_MOBILE', 'TSS_FAX', 'TSS_EMAIL');
//+ImportTable_MySQL_to_Tecdoc('tof_text_module_texts', 'TMT_ID', 'TMT_TEXT');
//+ImportTable_MySQL_to_Tecdoc('tof_text_modules', 'TMO_ID', 'TMO_LNG_ID', 'TMO_FIXED', 'TMO_TMT_ID');
//ImportTable_MySQL_to_Tecdoc('tof_trans_controls', 'TC_TRANS_UNIT', 'TC_CLASSNAME');
//0ImportTable_MySQL_to_Tecdoc('tof_trans_is_part_of', 'TPO_TRANS_UNIT', 'TPO_ISPARTOF');
//0ImportTable_MySQL_to_Tecdoc('tof_trans_terms', 'TTE_ID', 'TTE_LNG_ID', 'TTE_TERM');
//0ImportTable_MySQL_to_Tecdoc('tof_trans_translations', 'TTR_TTE_ID_FROM', 'TTR_TOF_TTE_ID_TO');
//0ImportTable_MySQL_to_Tecdoc('tof_trans_units', 'TU_CLASSNAME', 'TU_TYPE');
//0ImportTable_MySQL_to_Tecdoc('tof_trans_used_translation', 'TUT_TC_CLASSNAME', 'TUT_TC_TRANS_UNIT', 'TUT_LNG_ID', 'TUT_TTE_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_typ_country_specifics', 'TYC_TYP_ID', 'TYC_COU_ID', 'TYC_PCON_START', 'TYC_PCON_END', 'TYC_KW_FROM', 'TYC_KW_UPTO', 'TYC_HP_FROM', 'TYC_HP_UPTO', 'TYC_CCM', 'TYC_CYLINDERS', 'TYC_DOORS', 'TYC_TANK', 'TYC_KV_VOLTAGE_DES_ID', 'TYC_KV_ABS_DES_ID', 'TYC_KV_ASR_DES_ID', 'TYC_KV_ENGINE_DES_ID', 'TYC_KV_BRAKE_TYPE_DES_ID', 'TYC_KV_BRAKE_SYST_DES_ID', 'TYC_KV_CATALYST_DES_ID', 'TYC_KV_BODY_DES_ID', 'TYC_KV_STEERING_DES_ID', 'TYC_KV_STEERING_SIDE_DES_ID', 'TYC_MAX_WEIGHT', 'TYC_KV_MODEL_DES_ID', 'TYC_KV_AXLE_DES_ID', 'TYC_CCM_TAX', 'TYC_LITRES', 'TYC_KV_DRIVE_DES_ID', 'TYC_KV_TRANS_DES_ID');
//+ImportTable_MySQL_to_Tecdoc('tof_typ_suspensions', 'TSU_TYP_ID', 'TSU_NR', 'TSU_KV_SUSPENSION_DES_ID', 'TSU_KV_AXLE_POS_DES_ID', 'TSU_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_typ_voltages', 'TVO_TYP_ID', 'TVO_NR', 'TVO_KV_VOLTAGE_DES_ID', 'TVO_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_typ_wheel_bases', 'TWB_TYP_ID', 'TWB_NR', 'TWB_WHEEL_BASE', 'TWB_KV_AXLE_POS_DES_ID', 'TWB_CTM');
//+ImportTable_MySQL_to_Tecdoc('tof_type_numbers', 'TYN_TYP_ID', 'TYN_SEARCH_TEXT', 'TYN_KIND', 'TYN_DISPLAY_NR', 'TYN_CTM', 'TYN_GOP_NR', 'TYN_GOP_START');
//+ImportTable_MySQL_to_Tecdoc('tof_types', 'TYP_ID', 'TYP_CDS_ID', 'TYP_MMT_CDS_ID', 'TYP_MOD_ID', 'TYP_CTM', 'TYP_LA_CTM', 'TYP_SORT', 'TYP_PCON_START', 'TYP_PCON_END', 'TYP_KW_FROM', 'TYP_KW_UPTO', 'TYP_HP_FROM', 'TYP_HP_UPTO', 'TYP_CCM', 'TYP_CYLINDERS', 'TYP_DOORS', 'TYP_TANK', 'TYP_KV_VOLTAGE_DES_ID', 'TYP_KV_ABS_DES_ID', 'TYP_KV_ASR_DES_ID', 'TYP_KV_ENGINE_DES_ID', 'TYP_KV_BRAKE_TYPE_DES_ID', 'TYP_KV_BRAKE_SYST_DES_ID', 'TYP_KV_FUEL_DES_ID', 'TYP_KV_CATALYST_DES_ID', 'TYP_KV_BODY_DES_ID', 'TYP_KV_STEERING_DES_ID', 'TYP_KV_STEERING_SIDE_DES_ID', 'TYP_MAX_WEIGHT', 'TYP_KV_MODEL_DES_ID', 'TYP_KV_AXLE_DES_ID', 'TYP_CCM_TAX', 'TYP_LITRES', 'TYP_KV_DRIVE_DES_ID', 'TYP_KV_TRANS_DES_ID', 'TYP_KV_FUEL_SUPPLY_DES_ID', 'TYP_VALVES', 'TYP_RT_EXISTS');
//0ImportTable_MySQL_to_Tecdoc('tof_user_error_reports', 'ERR_ART_ID', 'ERR_LFD_NR', 'ERR_KIND', 'ERR_KV_CLASSIFICATION', 'ERR_SHORT_DESCRIPTION', 'ERR_ENG_ID', 'ERR_TYP_ID', 'ERR_AXL_ID', 'ERR_MRK_ID', 'ERR_TEXT', 'ERR_USS_ID', 'ERR_KV_STATE', 'ERR_DATE_STATUS_CHANGED', 'ERR_DATE_STATUS_REFRESHED', 'ERR_LINK', 'ERR_EXTERNAL_ID', 'ERR_ATTACHMENT', 'ERR_PRIVAT');
//0ImportTable_MySQL_to_Tecdoc('tof_user_error_reports_imp', 'ERR_ART_ARTICLE_NR', 'ERR_SUP_SUPPLIER_NR', 'ERR_LFD_NR', 'ERR_KIND', 'ERR_KV_CLASSIFICATION', 'ERR_SHORT_DESCRIPTION', 'ERR_ENG_ID', 'ERR_TYP_ID', 'ERR_AXL_ID', 'ERR_MRK_ID', 'ERR_TEXT', 'ERR_USS_ID', 'ERR_KV_STATE', 'ERR_DATE_STATUS_CHANGED', 'ERR_DATE_STATUS_REFRESHED', 'ERR_LINK', 'ERR_EXTERNAL_ID', 'ERR_ATTACHMENT', 'ERR_PRIVAT');
/*ImportTable_MySQL_to_Tecdoc('tof_user_settings', 'USS_ID', 'USS_PROFILE_NAME', 'USS_PROFILE_FIRST_NAME', 'USS_PROFILE_PASSWORD', 'USS_LNG_ID', 
		'USS_COU_ID', 'USS_PREFERRED_SECTION', 'USS_PREFERRED_SEARCH', 'USS_SHOW_LAST_VEHICLE', 'USS_SHOW_LAST_ENGINE', 'USS_SHOW_LAST_AXLE', 
		'USS_NODE_WITHOUT_LINKS', 'USS_EXPERT_SEARCH', 'USS_FILENAME', 'USS_DIRECTORY', 'USS_TITLE', 'USS_NAME', 'USS_FIRST_NAME', 'USS_ROLE', 
		'USS_COMPANY_NAME', 'USS_STREET', 'USS_POSTAL_CODE', 'USS_CITY', 'USS_POB', 'USS_POSTAL_CODE_POB', 'USS_COU_ID_ADDRESS', 'USS_TELEPHONE', 
		'USS_FAX', 'USS_EXTENSION', 'USS_MOBILE', 'USS_EMAIL', 'USS_WEB', 'USS_REGION', 'USS_VEHICLE_FILTER_ACTIVE', 'USS_ENGINE_FILTER_ACTIVE', 
		'USS_STREE_FILTER_ACTIVE', 'USS_BRAND_FILTER_ACTIVE', 'USS_MANU_MODEL_FILTER_ACTIVE', 'USS_TSD_ID', 'USS_TAX', 'USS_COU_CC', 
		'USS_COU_CC_ADDRESS', 'USS_SHOW_CRITERIA_DIALOG', 'USS_SHOW_IMPROVEMENTS_DIALOG', 'USS_KIND_OF_FILTER', 'USS_WINDOWS_USER', 
		'USS_EMAIL_ORDER_SUBJECT', 'USS_EMAIL_ORDER_TEXT', 'USS_ERR_TRACK_PASSWORD', 'USS_CUSTOMER_NUMBER', 'USS_VAT', 'USS_USTID_CC', 
		'USS_USTID_NR', 'USS_LOGO_PATH', 'USS_HOURLY_RATE_MECHANICS', 'USS_HOURLY_RATE_BODY', 'USS_HOURLY_RATE_ELECTRONICS', 'USS_SHOW_UPDATE', 
		'USS_LAST_UPDATE', 'USS_TAX_STANDARD', 'USS_TAX_REDUCED', 'USS_HESS_USER', 'USS_HESS_PASSWORD', 'USS_VRM_UK_USER', 'USS_VRM_UK_PASSWORD', 
		'USS_VRM_UK_INITIALS', 'USS_VRM_IE_USER', 'USS_VRM_IE_PASSWORD', 'USS_SIV_USER', 'USS_SIV_PASSWORD');
*/
//0ImportTable_MySQL_to_Tecdoc('tof_user_updates', 'UPD_INFO', 'UPD_INSTALL_DATE', 'UPD_RESULT', 'UPD_NAME', 'UPD_TYPE', 'UPD_SIZE');
//+ImportTable_MySQL_to_Tecdoc('tof_utility_direct', 'UTD_ART_ID', 'UTD_CTM', 'UTD_TEXT');
//0ImportTable_MySQL_to_Tecdoc('tof_vehicle_histories', 'VHI_USS_ID', 'VHI_TYP_ID', 'VHI_SORT', 'VHI_COU_ID_CAR_DDDW', 'VHI_COU_ID_CAR_DES', 'VHI_IS_MRK');
//0ImportTable_MySQL_to_Tecdoc('tup_package_log', 'TPL_ID', 'TPL_GROUP', 'TPL_VERSION', 'TPL_IMPORT_DATE', 'TPL_VERSION_DATE', 'TPL_STATUS', 'TPL_DESCRIPTION', 'TPL_PUBLISHER', 'TPL_OSUSER');
//0ImportTable_MySQL_to_Tecdoc('tup_step_log', 'TLG_TPL_ID', 'TLG_STEP', 'TLG_STATEMENT', 'TLG_MSG_TYPE', 'TLG_MESSAGE');
//0ImportTable_MySQL_to_Tecdoc('tup_substep_log', 'TSL_TPL_ID', 'TSL_STEP', 'TSL_SUBSTEP', 'TSL_STEP_TYPE', 'TSL_MESSAGE', 'TSL_STATEMENT');
}

function Main() {
	Initialize();
	Connect();
	ImportForm_MySQL_to_Tecdoc();
	//ShowAllTablesCount(true);
	Finalize();
}

Main()