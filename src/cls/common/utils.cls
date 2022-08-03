/// Description
Class common.utils
{

Parameter CLASSNAME = "FINANCE.RM.odpaiebrut.Record";

Parameter DELIMITER = ";";

Parameter DATEFORMAT = 3;

ClassMethod merge(package As %String)
{
    set ns = $NAMESPACE
    zn "IRISAPP"
    set sc=$$$OK
    set st = ##class(%SQL.Statement).%New()
    set rs = st.%PrepareClassQuery("%Dictionary.ClassDefinitionQuery","Summary")
	set rs =  st.%Execute()
    kill ^mergeTrace
    while rs.%Next() {	
        if rs.%GetData(1) [ package _ "." { 

            set class = ##class(%Dictionary.ClassDefinition).%OpenId(rs.%GetData(1)) 
            if $ISOBJECT(class) {
                if $ISOBJECT(class.Storages.GetAt(1)) {
            
                    set DataLocation = class.Storages.GetAt(1).DataLocation
                    set IndexLocation = class.Storages.GetAt(1).IndexLocation
                    set StreamLocation = class.Storages.GetAt(1).StreamLocation

                    
                    set sourceDataLocation = "^User."_$PIECE(DataLocation,".",2)
                    set sourceIndexLocation = "^User."_$PIECE(IndexLocation,".",2)
                    set sourceStreamLocation = "^User."_$PIECE(StreamLocation,".",2)

                    write "merging ",sourceDataLocation," into ",DataLocation,!

                    merge @DataLocation = @sourceDataLocation
                    merge @IndexLocation = @sourceIndexLocation
                    merge @StreamLocation = @sourceStreamLocation

                    set ^mergeTrace($i(^mergeTrace)) = $lb($zdt($h,3),sourceDataLocation)

                }
            }

        }
    }
    zn ns
    return sc
}

ClassMethod exportCSV(filename As %String = "\\epfrs43\odpaie$\ODPAIE012022.csv", verbose As %Boolean = 0) As %Status
{
    set sc = $$$OK
    s mgr = ##class(%SQL.Export.Mgr).%New()
    s mgr.FileName = filename
    write:verbose !,mgr.FileName
    s mgr.ClassName = ..#CLASSNAME
    write:verbose !,mgr.ClassName
    s mgr.TableName = $$$CLASSsqltablename($$$gWRK,mgr.ClassName)
    write:verbose !,mgr.TableName
    s mgr.Delimiter = ..#DELIMITER
    write:verbose !,mgr.Delimiter
    s mgr.StringQuote = $c(34)
    write:verbose !,mgr.StringQuote
    s mgr.DateFormat = ..#DATEFORMAT
    write:verbose !,mgr.DateFormat
    s mgr.TimeFormat = 1
    write:verbose !,mgr.TimeFormat
    s mgr.TimeStampFormat = 1
    write:verbose !,mgr.TimeStampFormat
    s mgr.NoCheck = $$$YES
    write:verbose !,mgr.NoCheck
    s mgr.HasHeaders = $$$YES
    write:verbose !,mgr.HasHeaders
    
    s cols="Journal:S;DatePieceComptable:S;TypePiece:S;Compte:S;TypeEcr:S;SectionSource:S;LibEcr:S;LibPiece:S;S:S;Sens:S;Montant:S;N"
    f i=1:1:$l(cols,";") {
        s c=$p(cols,";",i)
        d mgr.ColumnNames.Insert($p(c,":",1))
        d mgr.ColumnTypes.Insert($p(c,":",2))
    }
    
    d mgr.Export()
    return sc
}

}
