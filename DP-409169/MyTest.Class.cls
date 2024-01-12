Class MyTest.Class Extends (%RegisteredObject, %JSON.Adaptor)
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

    Write "Property after import: ",obj.streamProperty.Size,!
}

}
