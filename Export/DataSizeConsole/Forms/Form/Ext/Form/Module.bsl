////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Paths =
	"Constants
	|Catalogs
	|Documents
	|DocumentJournals
	|ChartsOfAccounts
	|ChartsOfCalculationTypes
	|ChartsOfCharacteristicTypes
	|InformationRegisters
	|AccumulationRegisters
	|AccountingRegisters
	|CalculationRegisters
	|BusinessProcesses
	|Tasks";
	
	SortBySize = True;
	
EndProcedure // OnCreateAtServer()

#EndRegion // EventHandlers

////////////////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS 

#Region CommandHandlers

&AtClient
Procedure ShowDataSize(Command)
	
	If Not IsBlankString(Paths) Then
		
		SpreadsheetDocument = DataSizeSpreadsheetDocument(Paths, SortBySize);
		
		SpreadsheetDocument.Show();
		
	EndIf;
	
EndProcedure // ShowDataSize()

#EndRegion // CommandHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

&AtServerNoContext
Function ValueInArray(Value)
	
	Result = New Array;
	Result.Add(Value);
	
	Return Result;
	
EndFunction // ValueInArray()

&AtServerNoContext
Function MetadataObjectByPath(ObjectsArrayItem)
	
	SplittedArrayItem = StrSplit(ObjectsArrayItem, ".");
	
	ObjectsCollectionName = SplittedArrayItem[0];
	ObjectName = SplittedArrayItem[1];
	
	Return Metadata[ObjectsCollectionName][ObjectName];
	
EndFunction // MetadataObjectByPath()

&AtServerNoContext
Function MetadataObjectsByPath(ObjectsArrayItem)
	
	Return Metadata[ObjectsArrayItem];
	
EndFunction // MetadataObjectsByPath()

&AtServerNoContext
Function MetadataObjectDataSize(MetadataObject)
	
	IncludeObjects = ValueInArray(MetadataObject);
	
	DataSize = GetDataBaseDataSize(, IncludeObjects);
	DataSize = DataSize / 1024 / 1024;	
	
	Return Round(DataSize, 2);	
	
EndFunction 

&AtServerNoContext
Procedure AddDataSizeTableRowForMetadataObject(DataSizeTable, MetadataObject)
	
	Row = DataSizeTable.Add();
		
	Row.MetadataObject = MetadataObject.FullName();
	Row.DataSizeMBytes = MetadataObjectDataSize(MetadataObject);
	
EndProcedure // AddDataSizeTableRowForMetadataObject()

&AtServerNoContext
Function ValueTableToSpreadsheetDocument(ValueTable)
		
	Builder = New ReportBuilder;		
	Builder.DataSource = New DataSourceDescription(ValueTable);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Builder.Put(SpreadsheetDocument);
	
	Return SpreadsheetDocument;
	
EndFunction // ValueTableToSpreadsheetDocument()

&AtServerNoContext
Function DataSizeTable()
	
	Result = New ValueTable;
	
	Result.Columns.Add("MetadataObject", New TypeDescription("String"));
	Result.Columns.Add("DataSizeMBytes", New TypeDescription("Number"));	

	Return Result;
	
EndFunction // DataSizeTable()

&AtServerNoContext
Function DataSizeSpreadsheetDocument(Val Paths, Val SortBySize)
		
	DataSizeTable	= DataSizeTable();	
	Paths			= StrSplit(Paths, Chars.LF);
	
	For Each Path In Paths Do
		
		Path = TrimAll(Path);
		
		If IsBlankString(Path) Then
			Continue;
		EndIf;
		
		IsCollection = StrOccurrenceCount(Path, ".") = 0;
		
		If IsCollection Then
			
			MetadataObjects = MetadataObjectsByPath(Path);
			
			For Each MetadataObject In Metadata[Path] Do
				AddDataSizeTableRowForMetadataObject(DataSizeTable, MetadataObject);
			EndDo;
			
		Else
			
			MetadataObject = MetadataObjectByPath(Path);
			
			AddDataSizeTableRowForMetadataObject(DataSizeTable, MetadataObject);
			
		EndIf;
		
	EndDo;
	
	If SortBySize Then
		DataSizeTable.Sort("DataSizeMBytes Desc");
	EndIf;
	
	Return ValueTableToSpreadsheetDocument(DataSizeTable);
		
EndFunction // DataSizeSpreadsheetDocument()

#EndRegion // Private