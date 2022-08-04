Class common.REST Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/" Method="GET" Call="version"/>
<Route Url="/pop/:classname/:nb" Method="GET" Call="pop"/>
<Route Url="/add" Method="POST" Call="add"/>
<Route Url="/import" Method="POST" Call="import"/>
<Route Url="/nb/:classname" Method="GET" Call="nb"/>
<Route Url="/kill/:classname" Method="DELETE" Call="kill"/>
<Route Url="/list/:classname" Method="GET" Call="list"/>
<Route Url="/list/:classname/:min/:max" Method="GET" Call="listTop"/>
<Route Url="/stream/:classname/:id/:property" Method="GET" Call="stream" />
</Routes>
}

ClassMethod importJSON() As %Status
{
    Try {
    set start=$zh // utilisé pour mesurer le temps de l'import du tableau JSON
    set sc=$$$OK,ts=$zdt($now(),3)
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={} // utilisé pour la réponse en JSON
    set json.system = $SYSTEM
    set json.ts = $zdt($h,3)
    set payload={}.%FromJSON(%request.Content) // récupération du payload envoyé par le client Winde
    set json.classname=payload.tablename // récupération du nom de ma classe dans lesquelles les données doivent être importées
    set json.init = payload.init // flag déterminant si les données/index/streams d'IRIS sont purgées avant import
    set class = ##class(%Dictionary.ClassDefinition).%OpenId(json.classname) // récupération des noms des globales de la classe IRIS en cas de 
    set IdLocation = class.Storages.GetAt(1).IdLocation
    set DataLocation = class.Storages.GetAt(1).DataLocation
    set IndexLocation = class.Storages.GetAt(1).IndexLocation
    set StreamLocation = class.Storages.GetAt(1).StreamLocation
    //set class.Super = "Exparf.common"
    set json.IdLocation=(IdLocation)
    if (json.init) { // si init = true
         kill @DataLocation,@IndexLocation,@StreamLocation  // suppression des données/index/streams de la classe dans IRIS
    }
    set imported=0 // initialisation du nombre d'enregistrements importés
    set array = payload.data.%GetIterator() // initialisation de l'itérateur pour parcourir le tableau d'enregistrements envoyés en JSON
    set json.nbRecords=payload.data.%Size() // récupération du nombre d'enregistrements contenus dans le tableau JSON
    set json.parseError=[],json.saveError=[] // initialisation des tableaux d'erreurs de PARSING ou de SAVE pour le rapport de l'import 
    set json.records=[]

    while array.%GetNext(.key,.value) { // récupération d'un enregistrement dans la variable "value" 
        #; set tmp = ##class(%Stream.GlobalBinary).%New()
        #; do value.%ToJSON(tmp)
        #; do tmp.Rewind()
        #; set x = {}.%FromJSON(tmp.ReadLineIntoStream())
        #; set longObject = {"a":(longStr),"b":(longStr)}
        #; set file=##class(%File).%New("/tmp/a.txt")
        #; do file.Open("WSN")
        #; do value.%ToJSON(file)
        #; do file.Close()
        #; do file.Open("RS")
        #; set newObject = {}.%FromJSON(file)
        #; write !,"Property newObject.a is "_$LENGTH(newObject.a)_" characters long."
        set a=$CLASSMETHOD(json.classname,"%New") // instanciation d'un nouvel enregistrement dans IRIS dans la variable "a"
 		#; set info={}
        #; set info.value = x.%ToJSON()
        #; set info.valueSize = $LENGTH(x.BStream)
        #; set info.BStreamGet = x.%Get("BStream")
        #; set info.name=(x.String)
        #; set info.extension=(x.extension)
        #; set info.size=($LENGTH(x.BStream))
        #; do json.records.%Push(info)

        #; for i = 1 : 1 : class.Properties.Count() {
        #;     set propertyName = class.Properties.GetAt(i).Name
        #;     if class.Properties.GetAt(i).Type [ "%Stream." {
        #;         do $METHOD($PROPERTY(a,propertyName),"Write",value.%Get(propertyName))
        #;     } else {
        #;         set $PROPERTY(a,propertyName) = value.%Get(propertyName)
        #;     }  
        #; }
        
        set parseOK=a.%JSONImport(value) // import des données contenues dans "value" vers la variable "a" (champ-à-champ)
        if 'parseOK { // si le PARSING de l'import JSON a levé une exception 
            set parseError={},parseErrorID=$i(^admin.migration(json.classname,ts,"parseError")) // initialisation des variables et globales pour le rapport d'erreurs de PARSING
            set parseError.key=key+1 // initialisation de la clé du rapport d'erreur à key + 1 (un tableau JSON commençant avec une key = 0)
            set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"key")=parseError.key // stockage de la key dans la globale du rapport de migration
            set parseError.error=$system.Status.GetErrorText(parseOK) // récupération du message d'erreur de PARSING
            set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"error")=parseError.error // stockage du messages d'erreur dans la globale du rapport de migration
            set parseError.content={} // initilisation du contenu des données reçues
            set parseError.content.name=$zstrip($piece(parseError.error,",",2),"*W") // récupération du nom de la propriété en erreur
            set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"name")=parseError.content.name
            set parseError.content.value=$PROPERTY(value,parseError.content.name) // récupération du contenu envoyé pour cette propriété
            set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"value")=parseError.content.value
            set parseError.content.length=$LENGTH(parseError.content.value) // récupération du nombre de caractères envoyés pour cette propriété
            set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"length")=parseError.content.length
            #; set parseError.content.fullContent=value
            do json.parseError.%Push(parseError) // ajout du détail de l'erreur dans le tableau du rapport d'erreurs
        }
        set saveOK=a.%Save() // validation + stockage de l'enregistrement dans IRIS
        if 'saveOK { // si le stockage dans IRIS a levé une exception
            set saveError={},saveOKID=$i(^admin.migration(json.classname,ts,"saveError")) //initilsation des variables et globales pour le rapport d'erreurs de SAVE
            set saveError.key=key+1 // initialisation de la clé du rapport d'erreur à key + 1 (un tableau JSON commençant avec une key = 0)
            set ^admin.migration(json.classname,ts,"saveError",saveOKID,"key")=saveError.key // stockage de la key dans la globale du rapport de migration
            set saveError.error=$system.Status.GetErrorText(saveOK) // récupération du message d'erreur de SAVE
            set ^admin.migration(json.classname,ts,"saveError",saveOKID,"key")=saveError.error // stockage du messages d'erreur dans la globale du rapport de migration
            do json.saveError.%Push(saveError) // ajout du détail de l'erreur dans le tableau du rapport d'erreurs
        } else {
            set imported=$INCREMENT(imported) // si le save n'a pas échoué, incrément du nombre d'enregistrements correctement importés dans IRIS pour le rapport
        }
    }
    set json.imported=imported // récupération dans le rapport du nombre d'enregistrements importés
    set json.elapse=$zh-start // récupération dans le rapport de la durée d'exécution de l'import
    set ^admin.migration(json.classname,ts,"import")="imported:"_imported_" size:"_json.size_" (elapse:"_json.elapse_")" // stockage de la durée d'exécution de l'import dans la globale du rapport de migration
    do json.%ToJSON() // export du rapport en JSON pour la réponse
    }
    catch ex {
            set sc=ex.AsStatus()
            set error={}
    set error.text = $system.Status.GetErrorText(sc)
            do error.%ToJSON()
        }
    return sc
}

ClassMethod importTEXT() As %Status
{
    Try {
    set start=$zh // utilisé pour mesurer le temps de l'import du tableau JSON
    set sc=$$$OK,ts=$zdt($now(),3)
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={} // utilisé pour la réponse en JSON
    set json.system = $SYSTEM
    set json.ts = $zdt($h,3)
   
    set payload = %request.Content // récupération du payload envoyé par le client Winde
    set json.size = payload.Size
    set line = payload.Read()
    set json.classname=$replace($piece($piece(line,","),":",2),"""","") // récupération du nom de ma classe dans lesquelles les données doivent être importées
    #; set json.init = payload.init // flag déterminant si les données/index/streams d'IRIS sont purgées avant import
    set class = ##class(%Dictionary.ClassDefinition).%OpenId(json.classname) // récupération des noms des globales de la classe IRIS en cas de 
    #; set IdLocation = class.Storages.GetAt(1).IdLocation
    #; set DataLocation = class.Storages.GetAt(1).DataLocation
    #; set IndexLocation = class.Storages.GetAt(1).IndexLocation
    #; set StreamLocation = class.Storages.GetAt(1).StreamLocation
    #; //set class.Super = "Exparf.common"
    #; set json.IdLocation=(IdLocation)
    #; if (json.init) { // si init = true
    #;      kill @DataLocation,@IndexLocation,@StreamLocation  // suppression des données/index/streams de la classe dans IRIS
    #; }
    set imported=0 // initialisation du nombre d'enregistrements importés
    while line '[ """data"":" { 
        set line = payload.Read()
    }
    set data = $PIECE(line,"[",2)

    set data = $PIECE(data, "{", 2)

    set stream = ##class(%Stream.GlobalCharacter).%New()
    do stream.Write(data)
    while data '[ "}" {
        // > 3.6MB
        set data = payload.Read()
        do stream.Write(data)
    }
    do stream.Rewind()
    while 'stream.AtEnd {
        set data = stream.Read()
        if data [ "}" {
            set data = $piece(data,"}")
            set a=$CLASSMETHOD(json.classname,"%New") // instanciation d'un nouvel enregistrement dans IRIS dans la variable "a"
            for i = 1 : 1 : $LENGTH(data,",") {
                #; set propertyName = class.Properties.GetAt(i).Name
                set propertyName = $PIECE($PIECE(data,",",i),":",1)
                if class.Properties.GetAt(i).Type [ "%Stream." {
                    do $METHOD($PROPERTY(a,propertyName),"Write",value.%Get(propertyName))
                } else {
                    set $PROPERTY(a,propertyName) = $PIECE($PIECE(data,",",i),":",2)
                }  
            }
        } else {
            // > 3.6MB

            set data = stream.Read()
        }
    }

    set json.data = data

    #; set array = payload.data.%GetIterator() // initialisation de l'itérateur pour parcourir le tableau d'enregistrements envoyés en JSON
    #; set json.nbRecords=payload.data.%Size() // récupération du nombre d'enregistrements contenus dans le tableau JSON
    #; set json.parseError=[],json.saveError=[] // initialisation des tableaux d'erreurs de PARSING ou de SAVE pour le rapport de l'import 
    #; set json.records=[]

    #; while array.%GetNext(.key,.value) { // récupération d'un enregistrement dans la variable "value" 
    #;     #; set tmp = ##class(%Stream.GlobalBinary).%New()
    #;     #; do value.%ToJSON(tmp)
    #;     #; do tmp.Rewind()
    #;     #; set x = {}.%FromJSON(tmp.ReadLineIntoStream())
    #;     #; set longObject = {"a":(longStr),"b":(longStr)}
    #;     #; set file=##class(%File).%New("/tmp/a.txt")
    #;     #; do file.Open("WSN")
    #;     #; do value.%ToJSON(file)
    #;     #; do file.Close()
    #;     #; do file.Open("RS")
    #;     #; set newObject = {}.%FromJSON(file)
    #;     #; write !,"Property newObject.a is "_$LENGTH(newObject.a)_" characters long."
    #;     set a=$CLASSMETHOD(json.classname,"%New") // instanciation d'un nouvel enregistrement dans IRIS dans la variable "a"
 	#; 	#; set info={}
    #;     #; set info.value = x.%ToJSON()
    #;     #; set info.valueSize = $LENGTH(x.BStream)
    #;     #; set info.BStreamGet = x.%Get("BStream")
    #;     #; set info.name=(x.String)
    #;     #; set info.extension=(x.extension)
    #;     #; set info.size=($LENGTH(x.BStream))
    #;     #; do json.records.%Push(info)

    #;     #; for i = 1 : 1 : class.Properties.Count() {
    #;     #;     set propertyName = class.Properties.GetAt(i).Name
    #;     #;     if class.Properties.GetAt(i).Type [ "%Stream." {
    #;     #;         do $METHOD($PROPERTY(a,propertyName),"Write",value.%Get(propertyName))
    #;     #;     } else {
    #;     #;         set $PROPERTY(a,propertyName) = value.%Get(propertyName)
    #;     #;     }  
    #;     #; }
        
    #;     set parseOK=a.%JSONImport(value) // import des données contenues dans "value" vers la variable "a" (champ-à-champ)
    #;     if 'parseOK { // si le PARSING de l'import JSON a levé une exception 
    #;         set parseError={},parseErrorID=$i(^admin.migration(json.classname,ts,"parseError")) // initialisation des variables et globales pour le rapport d'erreurs de PARSING
    #;         set parseError.key=key+1 // initialisation de la clé du rapport d'erreur à key + 1 (un tableau JSON commençant avec une key = 0)
    #;         set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"key")=parseError.key // stockage de la key dans la globale du rapport de migration
    #;         set parseError.error=$system.Status.GetErrorText(parseOK) // récupération du message d'erreur de PARSING
    #;         set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"error")=parseError.error // stockage du messages d'erreur dans la globale du rapport de migration
    #;         set parseError.content={} // initilisation du contenu des données reçues
    #;         set parseError.content.name=$zstrip($piece(parseError.error,",",2),"*W") // récupération du nom de la propriété en erreur
    #;         set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"name")=parseError.content.name
    #;         set parseError.content.value=$PROPERTY(value,parseError.content.name) // récupération du contenu envoyé pour cette propriété
    #;         set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"value")=parseError.content.value
    #;         set parseError.content.length=$LENGTH(parseError.content.value) // récupération du nombre de caractères envoyés pour cette propriété
    #;         set ^admin.migration(json.classname,ts,"parseError",parseErrorID,"length")=parseError.content.length
    #;         #; set parseError.content.fullContent=value
    #;         do json.parseError.%Push(parseError) // ajout du détail de l'erreur dans le tableau du rapport d'erreurs
    #;     }
    #;     set saveOK=a.%Save() // validation + stockage de l'enregistrement dans IRIS
    #;     if 'saveOK { // si le stockage dans IRIS a levé une exception
    #;         set saveError={},saveOKID=$i(^admin.migration(json.classname,ts,"saveError")) //initilsation des variables et globales pour le rapport d'erreurs de SAVE
    #;         set saveError.key=key+1 // initialisation de la clé du rapport d'erreur à key + 1 (un tableau JSON commençant avec une key = 0)
    #;         set ^admin.migration(json.classname,ts,"saveError",saveOKID,"key")=saveError.key // stockage de la key dans la globale du rapport de migration
    #;         set saveError.error=$system.Status.GetErrorText(saveOK) // récupération du message d'erreur de SAVE
    #;         set ^admin.migration(json.classname,ts,"saveError",saveOKID,"key")=saveError.error // stockage du messages d'erreur dans la globale du rapport de migration
    #;         do json.saveError.%Push(saveError) // ajout du détail de l'erreur dans le tableau du rapport d'erreurs
    #;     } else {
    #;         set imported=$INCREMENT(imported) // si le save n'a pas échoué, incrément du nombre d'enregistrements correctement importés dans IRIS pour le rapport
    #;     }
    #; }
    #; set json.imported=imported // récupération dans le rapport du nombre d'enregistrements importés
    #; set json.elapse=$zh-start // récupération dans le rapport de la durée d'exécution de l'import
    #; set ^admin.migration(json.classname,ts,"import")="imported:"_imported_" size:"_json.size_" (elapse:"_json.elapse_")" // stockage de la durée d'exécution de l'import dans la globale du rapport de migration
    do json.%ToJSON() // export du rapport en JSON pour la réponse
    }
    catch ex {
            set sc=ex.AsStatus()
            set error={}
    set error.text = $system.Status.GetErrorText(sc)
            do error.%ToJSON()
        }
    return sc
}

ClassMethod import() As %Status
{
    Try {
    set start=$zh // utilisé pour mesurer le temps de l'import du tableau JSON
    set sc=$$$OK,ts=$zdt($now(),3)
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={} // utilisé pour la réponse en JSON
    set json.system = $SYSTEM
    set json.ts = $zdt($h,3)
    set payload={}.%FromJSON(%request.Content) // récupération du payload envoyé par le client Winde
    set json.classname=payload.tablename // récupération du nom de ma classe dans lesquelles les données doivent être importées
    set json.init = payload.init // flag déterminant si les données/index/streams d'IRIS sont purgées avant import
    set class = ##class(%Dictionary.ClassDefinition).%OpenId(json.classname) // récupération des noms des globales de la classe IRIS en cas de 
    set IdLocation = class.Storages.GetAt(1).IdLocation
    set DataLocation = class.Storages.GetAt(1).DataLocation
    set IndexLocation = class.Storages.GetAt(1).IndexLocation
    set StreamLocation = class.Storages.GetAt(1).StreamLocation
    //set class.Super = "Exparf.common"
    set json.IdLocation=(IdLocation)
    if (json.init) { // si init = true
         kill @DataLocation,@IndexLocation,@StreamLocation  // suppression des données/index/streams de la classe dans IRIS
    }
    set imported=0 // initialisation du nombre d'enregistrements importés
    set array = payload.data.%GetIterator() // initialisation de l'itérateur pour parcourir le tableau d'enregistrements envoyés en JSON
    set json.nbRecords=payload.data.%Size() // récupération du nombre d'enregistrements contenus dans le tableau JSON
    set json.parseError=[],json.saveError=[] // initialisation des tableaux d'erreurs de PARSING ou de SAVE pour le rapport de l'import 
    set json.records=[]

    while array.%GetNext(.key,.value) { 
        set tmp = ##class(%Stream.GlobalBinary).%New()
        do value.%ToJSON(tmp)
        do tmp.Rewind()
        set x = {}.%FromJSON(tmp.ReadLineIntoStream())
        set a=$CLASSMETHOD(json.classname,"%New") 

        for i = 1 : 1 : class.Properties.Count() {
            set propertyName = class.Properties.GetAt(i).Name
            if class.Properties.GetAt(i).Type [ "%Stream." {
                #; set stream = x.%Get(propertyName,,"stream")
                do $METHOD($PROPERTY(a,propertyName),"CopyFrom",x.%Get(propertyName,,"stream"))
            } else {
                set $PROPERTY(a,propertyName) = x.%Get(propertyName)
            }  
        }
        set (a.Integer,a.Float,a.Double,a.Numeric) = a.BStream.Size
        set a.Timestamp = $zdt($h,3)
        set a.Date = +$H
        set a.Boolean = 1
        if a.CStream.Size = 0 {
            do a.CStream.CopyFrom(a.BStream)
        }
        set saveOK=a.%Save() 
    }
    set json.imported=imported // récupération dans le rapport du nombre d'enregistrements importés
    set json.elapse=$zh-start // récupération dans le rapport de la durée d'exécution de l'import
    set ^admin.migration(json.classname,ts,"import")="imported:"_imported_" size:"_json.size_" (elapse:"_json.elapse_")" // stockage de la durée d'exécution de l'import dans la globale du rapport de migration
    do json.%ToJSON() // export du rapport en JSON pour la réponse
    }
    catch ex {
            set sc=ex.AsStatus()
            set error={}
    set error.text = $system.Status.GetErrorText(sc)
            do error.%ToJSON()
        }
    return sc
}

ClassMethod kill(classname As %String) As %Status
{
    set start=$zh
    set sc=$$$OK,ts=$zdt($now(),3,,6)
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={}
    set json.classname=classname
    set json.status=$CLASSMETHOD(classname,"%KillExtent")
    set json.elapse=$zh-start
    set ^admin.migration(classname,ts,"killed")=json.status_" (elapse:"_json.elapse_")"
    do json.%ToJSON()
    return sc
}

ClassMethod pop(classname As %String, nb As %String) As %Status
{
    set start=$zh
    set sc=$$$OK
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={}
    set json.classname=classname
    set json.nb=nb
    set json.inserted=$CLASSMETHOD(classname,"Populate",nb)
    set json.elapse=$zh-start
    do json.%ToJSON()
    return sc
}

ClassMethod add() As %Status
{
    set start=$zh
    set sc=$$$OK
    set %response.ContentType= ..#CONTENTTYPEJSON
    set payload = {}.%FromJSON(%request.Content)
    set json={}
    set json.filename=payload.filename
    set sc = ##class(data.test).add(payload.filename)
    set json.sc = (sc)
    set json.elapse=$zh-start
    do json.%ToJSON()
    return sc
}

ClassMethod nb(classname As %String) As %Status
{
    set start=$zh
    set sc=$$$OK
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={}
    set json.classname=classname
    set class=##class(%Dictionary.CompiledClass).%OpenId(classname)
    set json.tableName=class.SqlSchemaName_"."_class.SqlTableName
    set tStatement=##class(%SQL.Statement).%New(1) 
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
    set start=$zh
    set sc=$$$OK
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={}
    set json.tablename=classname
    set json.data=[]
    #; set i=0
    set tStatement=##class(%SQL.Statement).%New() 
    set sc = tStatement.%PrepareClassQuery(classname,"Extent") 
    set result = tStatement.%Execute() 
    if 'result.%SQLCODE {  
        while result.%Next() { 
            set a=$CLASSMETHOD(classname,"%OpenId",result.%GetData(1))
            set sc=a.%JSONExportToStream(.str)
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
    set %response.ContentType= ..#CONTENTTYPEJSON
    set sc=$$$OK,i=min
    if min>max {
        set json={"ERROR":(min _ ">" _max)}
    } else {
        set json={"tablename": (classname),"init":true}
        set json.data=[]
        #; do json.%Push({"ts":($zdt($h,3))})
        set tStatement=##class(%SQL.Statement).%New() 
        set sc = tStatement.%PrepareClassQuery(classname,"Extent") 
        set result = tStatement.%Execute() 
        if 'result.%SQLCODE {  
            while i<=max && result.%Next() { 
                set a=$CLASSMETHOD(classname,"%OpenId",i)
                set sc=a.%JSONExportToStream(.str)
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
    set sc=$$$OK
    set %response.ContentType= ..#CONTENTTYPEJSON
    set json={}
    set json.version=($zv)
    set json.date=($zdt($h,3))
    set json.system=($System)
    set json.username=($Username)
    set json.roles=($Roles)
    set json.namespace=($Namespace)
    set nls=##class(%SYS.NLS.Locale).GetLanguage()
    set json.country=($listget(nls,1))
    set json.lang=($listget(nls,2))
    set json.JavaHomeDirectory=$SYSTEM.Util.JavaHomeDirectory()
    set json.JavaExe=$SYSTEM.Util.JavaExe()
    do json.%ToJSON()
    #; write "Hello "_$USERNAME
    return sc
}

ClassMethod stream(classname As %String, id As %Integer, property As %String) As %Status
{
    if $CLASSMETHOD(classname,"%ExistsId",id) {
        
        set data=$CLASSMETHOD(classname,"%OpenId",id)
        set stream = $PROPERTY(data,property)
        set %response.ContentType="application/octet-stream"
        if data.extension = "pdf" {
            set %response.ContentType="application/pdf"
        } 
        if data.extension = "gif" {
            set %response.ContentType="image/gif"
        }

        set sc = $METHOD(stream,"OutputToDevice")
    } else {
        set sc=$SYSTEM.Status.Error(5001,id_" doesn't exist")
    }
    s %response.Status=200
    return sc
}

}
