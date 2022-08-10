Class common.REST Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

Parameter CONTENTTYPEPDF = "application/pdf";

Parameter CONTENTTYPEGIF = "image/gif";

Parameter CONTENTTYPEOCTETSTREAM = "application/octet-stream";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/" Method="GET" Call="version"/>
<Route Url="/pop/:classname/:nb" Method="GET" Call="pop"/>
<Route Url="/add" Method="POST" Call="add"/>
<Route Url="/import" Method="POST" Call="import"/>
<Route Url="/importjson" Method="POST" Call="importJSON"/>
<Route Url="/nb/:classname" Method="GET" Call="nb"/>
<Route Url="/kill/:classname" Method="DELETE" Call="kill"/>
<Route Url="/list/:classname" Method="GET" Call="list"/>
<Route Url="/list/:classname/:min/:max" Method="GET" Call="listTop"/>
<Route Url="/stream/:classname/:property/:id" Method="GET" Call="stream" />
</Routes>
}

ClassMethod importJSON() As %Status
{
    Try {
        set start = $zh 
        set sc = $$$OK
        set %response.ContentType = ..#CONTENTTYPEJSON
        set json = {} 
        set json.system = $SYSTEM
        set json.ts = $zdt($now(),3,,6)
        set payload = {}.%FromJSON(%request.Content) 
        set json.classname = payload.tablename 
        set json.init = payload.init 
        set imported = 0 
        set array = payload.data.%GetIterator() 
        set json.nbRecords = payload.data.%Size() 
        set json.parseError = [],json.saveError = [] 
        set ^import(json.classname,json.ts,"received") = $Get(^import.received(json.classname,json.ts,"received"),0) + json.nbRecords
        
        if ##class(%Dictionary.ClassDefinition).%ExistsId(json.classname) {
            set class = ##class(%Dictionary.ClassDefinition).%OpenId(json.classname)  
            set IdLocation = class.Storages.GetAt(1).IdLocation
            set DataLocation = class.Storages.GetAt(1).DataLocation
            set IndexLocation = class.Storages.GetAt(1).IndexLocation
            set StreamLocation = class.Storages.GetAt(1).StreamLocation
            set json.IdLocation = (IdLocation)
            if (json.init) { 
                kill @DataLocation,@IndexLocation,@StreamLocation 
            }
            
            while array.%GetNext(.key,.value) { 
                set a=$CLASSMETHOD(json.classname,"%New") 
                set ID = $INCREMENT(^admin.migration(json.classname))
                set parseOK=a.%JSONImport(value)    
                if 'parseOK { 
                set parseError = {}
                set parseError.error = $system.Status.GetErrorText(parseOK)
                set parseError.key = (key) 
                set ^admin.migration(json.classname,"parse error",$zdt($now(),3,,6)) = parseError.error 
                do json.parseError.%Push(parseError) 
            } 
                set saveOK = a.%Save() 
                if 'saveOK { 
                    set saveError = {}
                    set saveError.key = (key)
                    set saveError.error = ($system.Status.GetErrorText(saveOK)) 
                    set ^admin.migration(json.classname,"save error",ID) = saveError.error 
                    do json.saveError.%Push(saveError) 
                } else {
                    set imported=$INCREMENT(imported) 
                }
            }

        } else {
            set sc = $SYSTEM.Status.Error(5001,json.classname _ " doesn't exist")
            set ^admin.migration(json.classname,"error","non existing class") = "" 
        }
        set json.imported = imported 
        set ^import(json.classname,json.ts,"imported") = $Get(^import.imported(json.classname,json.ts,"imported"),0) + json.imported
        set json.elapse = $zh-start 
        set ^admin.migration(json.classname,"import",$zdt($now(),3,,6)) = "imported:"_imported_" size:"_json.nbRecords_" (elapse:"_json.elapse_")" 
        do json.%ToJSON() 
    }
    Catch ex {
        set sc = ex.AsStatus()
    }
    return sc
}

ClassMethod import() As %Status
{
    Try {
        set start = $zh 
        set sc = $$$OK
        set %response.ContentType= ..#CONTENTTYPEJSON
        set json = {} 
        set json.system = $SYSTEM
        set json.ts = $zdt($now(),3,,6)
        set payload = {}.%FromJSON(%request.Content) 
        set json.classname=payload.tablename 
        set json.init = payload.init 
        set imported = 0 
        set array = payload.data.%GetIterator() 
        set json.nbRecords=payload.data.%Size() 
        set json.parseError=[],json.saveError=[] 
        set ^import(json.classname,json.ts,"received") = $Get(^import.received(json.classname,json.ts,"received"),0) + json.nbRecords
        if ##class(%Dictionary.ClassDefinition).%ExistsId(json.classname) {
            set class = ##class(%Dictionary.ClassDefinition).%OpenId(json.classname)  
            set IdLocation = class.Storages.GetAt(1).IdLocation
            set DataLocation = class.Storages.GetAt(1).DataLocation
            set IndexLocation = class.Storages.GetAt(1).IndexLocation
            set StreamLocation = class.Storages.GetAt(1).StreamLocation
            set json.IdLocation=(IdLocation)
            if (json.init) { 
                kill @DataLocation,@IndexLocation,@StreamLocation 
            }
            
            while array.%GetNext(.key,.value) { 
                set a =$CLASSMETHOD(json.classname,"%New") 
                set ID = $INCREMENT(^admin.migration(json.classname))
                #; set parseOK=a.%JSONImport(value) 
                set tmp = ##class(%Stream.GlobalCharacter).%New()
                do value.%ToJSON(tmp)
                do tmp.Rewind()
                set x = {}.%FromJSON(tmp.ReadLineIntoStream())

                for i = 1 : 1 : class.Properties.Count() {
                    set propertyName = class.Properties.GetAt(i).Name
                    if x.%IsDefined(propertyName) {
                        if 'class.Properties.GetAt(i).Calculated {
                            if class.Properties.GetAt(i).Type [ "%Stream." {
                                if x.%Get(propertyName,,"stream").Size > 0 {
                                    set ^admin.migration(json.classname,ID,propertyName,x.%Get(propertyName,,"stream").Size) =  x.%Get(propertyName,,"stream").Read(100)
                                    if class.Properties.GetAt(i).Type = "%Stream.GlobalBinary" {
                                        set tmp = ##class(%Stream.GlobalCharacter).%New()
                                        do tmp.CopyFrom(x.%Get(propertyName,,"stream"))
                                        do tmp.Rewind() 
                                        while 'tmp.AtEnd {
                                            do $METHOD($PROPERTY(a,propertyName),"Write",$system.Encryption.Base64Decode(tmp.Read()))
                                        }
                                    } 
                                    if class.Properties.GetAt(i).Type = "%Stream.GlobalCharacter" {
                                        do $METHOD($PROPERTY(a,propertyName),"CopyFrom",x.%Get(propertyName,,"stream"))
                                    }
                                }
                            } else {
                                if class.Properties.GetAt(i).Type = "%Date"  {
                                    if x.%Get(propertyName) '= "" {
                                        set ^admin.migration(json.classname,ID,propertyName) = x.%Get(propertyName)
                                        set $PROPERTY(a,propertyName) = $zdh(x.%Get(propertyName),3)
                                    }
                                } elseif class.Properties.GetAt(i).Type = "%TimeStamp"  {
                                    if x.%Get(propertyName) '= "" {
                                    set ^admin.migration(json.classname,ID,propertyName) = x.%Get(propertyName)
                                    set $PROPERTY(a,propertyName) = $tr(x.%Get(propertyName),"TZ"," ")
                                    }
                                } else {
                                    set ^admin.migration(json.classname,ID,propertyName) = x.%Get(propertyName)
                                    set $PROPERTY(a,propertyName) = x.%Get(propertyName)
                                }
                            }  
                        }
                    }
                }
                set saveOK = a.%Save() 
                if 'saveOK { 
                    set saveError = {}
                    set saveError.key = (key)
                    set saveError.error = ($system.Status.GetErrorText(saveOK)) 
                    set ^admin.migration(json.classname,"save error",ID) = saveError.error 
                    do json.saveError.%Push(saveError) 
                } else {
                    set imported = $INCREMENT(imported) 
                }
            }

        } else {
            set sc = $SYSTEM.Status.Error(5001,json.classname _ " doesn't exist")
            set ^admin.migration(json.classname,"error","non existing class") = "" 
        }
        set json.imported = imported 
        set ^import(json.classname,json.ts,"imported") = $Get(^import.imported(json.classname,json.ts,"imported"),0) + json.imported
        set json.elapse = $zh-start 
        set ^admin.migration(json.classname,"import",$zdt($now(),3,,6)) = "imported:"_imported_" size:"_json.nbRecords_" (elapse:"_json.elapse_")" 
        do json.%ToJSON() 
    }
    Catch ex {
        set sc = ex.AsStatus()
    }
    return sc
}

ClassMethod kill(classname As %String) As %Status
{
    set start = $zh
    set sc = $$$OK,ts = $zdt($now(),3,,6)
    set %response.ContentType = ..#CONTENTTYPEJSON
    set json = {}
    set json.classname = classname
    set json.status = $CLASSMETHOD(classname,"%KillExtent")
    set json.elapse = $zh-start
    set ^admin.migration(classname,ts,"killed") = json.status_" (elapse:"_json.elapse_")"
    do json.%ToJSON()
    return sc
}

ClassMethod pop(classname As %String, nb As %String) As %Status
{
    set start = $zh
    set sc = $$$OK
    set %response.ContentType = ..#CONTENTTYPEJSON
    set json = {}
    set json.classname = classname
    set json.nb=nb
    set json.inserted = $CLASSMETHOD(classname,"Populate",nb)
    set json.elapse = $zh-start
    do json.%ToJSON()
    return sc
}

ClassMethod add() As %Status
{
    set start = $zh
    set sc = $$$OK
    set %response.ContentType = ..#CONTENTTYPEJSON
    set payload = {}.%FromJSON(%request.Content)
    set json = {}
    set json.filename = payload.filename
    set sc = ##class(data.test).add(payload.filename)
    set json.sc = (sc)
    set json.elapse = $zh-start
    do json.%ToJSON()
    return sc
}

ClassMethod nb(classname As %String) As %Status
{
    set start = $zh
    set sc = $$$OK
    set %response.ContentType = ..#CONTENTTYPEJSON
    set json = {}
    set json.classname = classname
    set class = ##class(%Dictionary.CompiledClass).%OpenId(classname)
    set json.tableName = class.SqlSchemaName_"."_class.SqlTableName
    set tStatement = ##class(%SQL.Statement).%New(1) 
    set sql = 2
    set sql(1) = "select count(*)" 
    set sql(2) = "from "_json.tableName
    set sc = tStatement.%Prepare(.sql) 
    set result = tStatement.%Execute() 
    if 'result.%SQLCODE {  
        do result.%Next()
        set json.nb=result.%GetData(1)
    }
    set json.elapse=$zh-start
    do json.%ToJSON()
    return sc
}

ClassMethod list(classname As %String) As %Status
{
    set start = $zh
    set sc = $$$OK
    set %response.ContentType = ..#CONTENTTYPEJSON
    set json = {}
    set json.tablename = classname
    set json.data = []
    #; set i=0
    set tStatement = ##class(%SQL.Statement).%New() 
    set sc = tStatement.%PrepareClassQuery(classname,"Extent") 
    set result = tStatement.%Execute() 
    if 'result.%SQLCODE {  
        while result.%Next() { 
            set a = $CLASSMETHOD(classname,"%OpenId",result.%GetData(1))
            set sc = a.%JSONExportToStream(.str)
            do json.data.%Push({}.%FromJSON(str))
            #; do $INCREMENT(i)
        } 
    }
    #; set json.nb=i
    #; set json.elapse=$zh-start
    do json.%ToJSON()
    kill result
    return sc
}

ClassMethod listTop(classname As %String, min As %Integer, max As %Integer) As %Status
{
    set start=$zh
    set %response.ContentType = ..#CONTENTTYPEJSON
    set sc = $$$OK,i = min
    if min > max {
        set json = {"ERROR":(min _ ">" _max)}
    } else {
        set json = {"tablename": (classname),"init":true}
        set json.data = []
        #; do json.%Push({"ts":($zdt($h,3))})
        set tStatement = ##class(%SQL.Statement).%New() 
        set sc = tStatement.%PrepareClassQuery(classname,"Extent") 
        set result = tStatement.%Execute() 
        if 'result.%SQLCODE {  
            while i <= max && result.%Next() { 
                set a = $CLASSMETHOD(classname,"%OpenId",i)
                set sc = a.%JSONExportToStream(.str)
                do json.data.%Push({}.%FromJSON(str))
                do $INCREMENT(i)
            } 
        }
    }
    write ""
    do json.%ToJSON()
    kill result
    return $$$OK
}

ClassMethod version() As %Status
{
    set sc = $$$OK
    set %response.ContentType = ..#CONTENTTYPEJSON
    set json = {}
    set json.version = ($zv)
    set json.date = ($zdt($h,3))
    set json.system = ($System)
    set json.username = ($Username)
    set json.roles = ($Roles)
    set json.namespace = ($Namespace)
    set nls = ##class(%SYS.NLS.Locale).GetLanguage()
    set json.country = ($listget(nls,1))
    set json.lang = ($listget(nls,2))
    set json.JavaHomeDirectory = $SYSTEM.Util.JavaHomeDirectory()
    set json.JavaExe = $SYSTEM.Util.JavaExe()
    do json.%ToJSON()
    #; write "Hello "_$USERNAME
    return sc
}

ClassMethod stream(classname As %String, property As %String, id As %Integer) As %Status
{
    if $CLASSMETHOD(classname,"%ExistsId",id) {
        set data = $CLASSMETHOD(classname,"%OpenId",id)
        set stream = $PROPERTY(data,property)
        set %response.ContentType = ..#CONTENTTYPEOCTETSTREAM
        if data.extension = "pdf" {
            set %response.ContentType = ..#CONTENTTYPEPDF 
        } 
        if data.extension = "gif" {
            set %response.ContentType = ..#CONTENTTYPEGIF 
        }
    set sc = $METHOD(stream,"OutputToDevice")
    } else {
        set sc = $SYSTEM.Status.Error(5001,id_" doesn't exist")
    }
    set %response.Status=200
    return sc
}

}
