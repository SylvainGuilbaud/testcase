/// <a target="_blank" 
/// href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_appx_limits#RCOS_appx_limits_string_length">
/// String Length Limit
/// </a>
Class MyTest.Class Extends (%RegisteredObject, %JSON.Adaptor, %XML.Adaptor)
{

Property streamProperty As %Stream.GlobalCharacter;

ClassMethod test() As %Status
{
    Set sc = $$$OK
    for size = 3.641, 3.645 {
        write !,"Size: ",size," MB",!
        do ##class(MyTest.Class).import(size*1000)
    }
    Return sc
}

ClassMethod import(maxsize As %Integer = 3641)
{
    Set stream = ##class(%Stream.FileCharacter).%New()

    Do stream.Write("<MyTest.Class><streamProperty>")
    set ^||data=""
    For i = 1:1:maxsize {
        set ^||data=^||data _ $j("x",1000)
        if $LENGTH(^||data)>3500000 {
            Do stream.Write(^||data)
            set ^||data=""
        }
    }
    Do stream.Write(^||data)
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

    kill (maxsize)

    Set stream = ##class(%Stream.FileCharacter).%New()
    
    Do stream.Write("{""streamProperty"":""")
    set ^||data=""
      For i = 1:1:maxsize {
        set ^||data=^||data _ $j("x",1000)
        if $LENGTH(^||data)>3500000 {
            Do stream.Write(^||data)
            set ^||data=""
        }
    }
    Do stream.Write(^||data)
    Do stream.Write("""}")
    Do stream.Rewind()

    Write "JSON stream length: ",stream.Size,!
    
    Set obj = ..%New()
    Do obj.%JSONImport(stream)
    Write "JSON Property after import: ",obj.streamProperty.Size,!
}

}
