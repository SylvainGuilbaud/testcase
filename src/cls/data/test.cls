Class data.test Extends (%Persistent, %XML.Adaptor, %JSON.Adaptor, %Populate) [ ClassType = persistent ]
{

Property String As %String(MAXLEN = "", POPSPEC = "Mission()");

Property BStream As %Stream.GlobalBinary(POPSPEC = "##class(data.test).BStreamPop()");

Property CStream As %Stream.GlobalCharacter(POPSPEC = "##class(data.test).CStreamPop()");

Property Numeric As %Numeric;

Property Integer As %Integer;

Property Float As %Float;

Property Double As %Double;

Property Date As %Date;

Property Timestamp As %TimeStamp;

Property Boolean As %Boolean;

Property extension As %String [ InitialExpression = "pdf" ];

Property created As %TimeStamp [ InitialExpression = {$zdt($now(),3,,6)} ];

Index StringIndex On String;

Index BStreamIndex On BStream;

Index CStreamIndex On CStream;

Index NumericIndex On Numeric;

Index IntegerIndex On Integer;

Index FloatIndex On Float;

Index DoubleIndex On Double;

Index DateIndex On Date;

Index TimestampIndex On Timestamp;

Index BooleanIndex On Boolean;

ClassMethod add(filename As %String = "") As %Status
{
    set sc=$$$OK
    Try {
        // default value if filename parameter is null
        set:filename="" filename = $system.Util.DataDirectory()_"docs/copyright.pdf"
        if ##class(%File).Exists(filename) {
            set a = ..%New()
            set a.String = $PIECE(filename,"/",*)
            set a.extension = $PIECE(a.String,".",*)
            set file=##class(%Stream.FileBinary).%New()
            set sc=file.LinkToFile(filename)
            do a.BStream.CopyFrom(file)
            do a.CStream.CopyFrom(file)
            set a.Numeric = a.BStream.Size
            set a.Integer = a.BStream.Size
            set a.Float = a.BStream.Size
            set a.Double = a.BStream.Size
            set a.Date = +$H
            set a.Timestamp = $zdt($h,3)
            set a.Boolean = 1
            set sc = a.%Save()
        } else {
            set sc = $system.Status.Error("5001",filename _ " doesn't exist")
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    
    return sc
}

ClassMethod BStreamPop() As %Stream.GlobalBinary
{
    set file=##class(%Stream.FileBinary).%New()
    set filename=$system.Util.DataDirectory()_"docs/copyright.pdf"
	set sc=file.LinkToFile(filename)
    set stream=##class(%Stream.GlobalBinary).%New()
    do stream.CopyFrom(file)
    return stream
}

ClassMethod CStreamPop() As %Stream.GlobalCharacter
{
    set file=##class(%Stream.FileCharacter).%New()
    set filename=$system.Util.ManagerDirectory()_"messages.log"
	set sc=file.LinkToFile(filename)
    set stream=##class(%Stream.GlobalCharacter).%New()
    do stream.CopyFrom(file)
    return stream
}

ClassMethod extractBinary(id As %Integer, extension As %String = "pdf", directory As %String = "tmp") As %Status
{
    set sc=$$$OK
    if ..%ExistsId(id) {
        set data=..%OpenId(id)
        set directory=##class(%File).NormalizeDirectory($system.Util.DataDirectory()_directory)
        do:'##class(%File).DirectoryExists(directory) ##class(%File).CreateDirectoryChain(directory)
        set filename=directory_id_"_BStream."_extension
        set file=##class(%Stream.FileBinary).%New()
        set sc= file.LinkToFile(filename)
        set sc=file.CopyFrom(data.BStream)
        set sc=file.%Save()
        write:sc filename," successfully extracted (",data.BStream.Size,")",file.Size,!
    } else {
        set sc=$SYSTEM.Status.Error(5001,id_" doesn't exist")
    }
    return sc
}

ClassMethod extractCharacter(id As %Integer, extension As %String = "txt", directory As %String = "tmp") As %Status
{
    set sc=$$$OK
    if ..%ExistsId(id) {
        set data=..%OpenId(id)
        set directory=##class(%File).NormalizeDirectory($system.Util.DataDirectory()_directory)
        do:'##class(%File).DirectoryExists(directory) ##class(%File).CreateDirectoryChain(directory)
        set filename=directory_id_"_CStream."_extension
        set file=##class(%Stream.FileCharacter).%New()
        set sc= file.LinkToFile(filename)
        set sc=file.CopyFrom(data.CStream)
        set sc=file.%Save()
        write:sc filename," successfully extracted (",data.CStream.Size,")",file.Size,!
    } else {
        set sc=$SYSTEM.Status.Error(5001,id_" doesn't exist")
    }
    return sc
}

Storage Default
{
<Data name="testDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>String</Value>
</Value>
<Value name="3">
<Value>BStream</Value>
</Value>
<Value name="4">
<Value>CStream</Value>
</Value>
<Value name="5">
<Value>Numeric</Value>
</Value>
<Value name="6">
<Value>Integer</Value>
</Value>
<Value name="7">
<Value>Float</Value>
</Value>
<Value name="8">
<Value>Double</Value>
</Value>
<Value name="9">
<Value>Date</Value>
</Value>
<Value name="10">
<Value>Timestamp</Value>
</Value>
<Value name="11">
<Value>Boolean</Value>
</Value>
<Value name="12">
<Value>extension</Value>
</Value>
<Value name="13">
<Value>created</Value>
</Value>
</Data>
<DataLocation>^data.testD</DataLocation>
<DefaultData>testDefaultData</DefaultData>
<ExtentSize>2</ExtentSize>
<IdLocation>^data.testD</IdLocation>
<IndexLocation>^data.testI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="BStream">
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Boolean">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="CStream">
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Date">
<AverageFieldSize>4</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Double">
<AverageFieldSize>10</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Float">
<AverageFieldSize>4</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Integer">
<AverageFieldSize>6</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Numeric">
<AverageFieldSize>5.5</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="String">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Timestamp">
<AverageFieldSize>21</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="extension">
<AverageFieldSize>6</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<SQLMap name="BStreamIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="BooleanIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="CStreamIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="DateIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="DoubleIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="FloatIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="IntegerIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="NumericIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="StringIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="TimestampIndex">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^data.testS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
