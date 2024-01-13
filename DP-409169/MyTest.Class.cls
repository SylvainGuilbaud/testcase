Class MyTest.Class Extends (%RegisteredObject, %JSON.Adaptor, %XML.Adaptor)
{

Property streamProperty As %Stream.GlobalCharacter;

ClassMethod import(maxstring As %Boolean)
{
    Set limit = $select($get(maxstring, 1):4000, 1:10)

    Set stream = ##class(%Stream.FileCharacter).%New()
    
    Do stream.Write("{""streamProperty"":""")
    For i = 1:1:limit {
        Do stream.Write($j("x",1000))
    }
    Do stream.Write("""}")
    Do stream.Rewind()

    Write "JSON stream length: ",stream.Size,!
    
    Set obj = ..%New()
    Do obj.%JSONImport(stream)
    Write "JSON Property after import: ",obj.streamProperty.Size,!

    kill (limit)

    Set stream = ##class(%Stream.FileCharacter).%New()

    Do stream.Write("<MyTest.Class><streamProperty>")
    For i = 1:1:limit {
        Do stream.Write($j("x",1000))
    }
    Do stream.Write("</streamProperty></MyTest.Class>")
    Do stream.Rewind()

    Write "XML stream length: ",stream.Size,!
    
    set reader = ##class(%XML.Reader).%New()
    set status = reader.OpenStream(stream)
    do reader.Correlate(..%ClassName(1),..%ClassName(1))
    while reader.Next(.obj,.status) {
        if $ISOBJECT(obj) {
            Write "XML Property after import: ",obj.streamProperty.Size,!
        }
    }
}

}
