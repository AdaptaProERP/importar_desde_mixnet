// Programa   : IMPORTMIX
// Fecha/Hora : 06/10/2003 16:18:52
// Propósito  : Importar Datos desde DP19
// Creado Por : Miguel Figueroa
// Llamado por: DPMENU	 
// Aplicación : Todas
// Tabla      : Todas

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  Local cFile:="\dpwin32\dpwin32.exe"
  LOCAL cId  :="MIXNET",cDir:=PADR(CURDRIVE()+":\Mix\",40)
  LOCAL oData:=DATASET(cId,"ALL")

  cDir:=oData:Get("cDir",cDir)
  cDir:=STRTRAN(cDir,"\"+"\","\")
  oData:End()

  oImpMix:=DPEDIT():New("Importar Datos desde MixNet","forms\Import20.edt","oImpMix",.T.)
 
  oImpMix:nFiles :=0
  oImpMix:nRecord:=0
  oImpMix:cDsn   :=oDp:cDsnData 
  oImpMix:oMeterT:=NIL
  oImpMix:oMeterR:=NIL
  oImpMix:cDir   :=cDir
  oImpMix:nTables:=0
  oImpMix:lInicia:=.F.
  oImpMix:lTransa:=.F.
  oImpMix:lMsgBar:=.F.

  oImpMix:lInv   :=.F.
  oImpMix:lCxP   :=.F.
  oImpMix:lCxC   :=.F.
  oImpMix:lCaj   :=.F.
  oImpMix:lBco   :=.F.
  oImpMix:lCon   :=.F.

  oImpMix:cMemo  :="Este Proceso de Migración de Datos no Genera ningún tipo de Garantía."+CRLF+;
                  "Es necesario realizar respaldo de Datos Antes de Ejecutar este Proceso."+CRLF+;
                  "Todos los Datos Actuales serán Borrados."+CRLF+CRLF+;
                  "No es posible Garantizar los Mismos Resultados que Emiten los Datos"+CRLF+;
                  "de Origen, Debido a la Diferencia en el Diseño de la Base de Datos e "+CRLF+;
                  "Integridad Referencial"

  @ 3,2 SAY "Directorio Destino"

  @ 3,2 SAY oImpMix:oSayTable  PROMPT "Tablas:" UPDATE
  @ 3,2 SAY oImpMix:oSayRecord PROMPT "Registros:"

//  @ 3,2 SAY "BD Actual:"
//  @ 4,2 SAY oImpMix:cDsn 

  @ 1,1 BMPGET oImpMix:oDIR VAR oImpMix:cDir NAME "BITMAPS\FOLDER5.BMP";
                               ACTION (cDir:=cGetDir(oImpMix:cDir),;
                                       IIF(!EMPTY(cDir),oImpMix:cDir:=PADR(cDir,30),NIL),;
                                       oImpMix:oDIR:Refresh(.t.))

  @ 02,01 METER oImpMix:oMeterT VAR oImpMix:nFiles
  @ 02,01 METER oImpMix:oMeterR VAR oImpMix:nRecord

  @ 5.4,29.0 CHECKBOX oImpMix:oInicia VAR oImpMix:lInicia  PROMPT ANSITOOEM("Borrar Datos Actuales")
  @ 6.4,29.0 CHECKBOX oImpMix:oTransa VAR oImpMix:lTransa  PROMPT ANSITOOEM("Importar Transacciones")

  @ .5,.1 GROUP oGrp TO 10,10 PROMPT "Aplicaciones"


  @ 5.5,1.0 CHECKBOX oImpMix:lInv  PROMPT ANSITOOEM("Inventario") 
  @ 6.5,1.0 CHECKBOX oImpMix:lCxP  PROMPT ANSITOOEM("Compras   ") 

  @ 5.5,20.0 CHECKBOX oImpMix:lCxC  PROMPT ANSITOOEM("Ventas CxC") 
  @ 6.5,20.0 CHECKBOX oImpMix:lCaj  PROMPT ANSITOOEM("Caja     ") 

  @ 5.5,30.0 CHECKBOX oImpMix:lBco  PROMPT ANSITOOEM("Bancos      ") 
  @ 6.5,30.0 CHECKBOX oImpMix:lCon  PROMPT ANSITOOEM("Contabilidad") 

  @ 02,01 GET oImpMix:oMemo VAR oImpMix:cMemo MULTILINE READONLY

  @ 6,07 BUTTON "Iniciar " ACTION  oImpMix:Import()
  @ 6,10 BUTTON "Cerrar  " ACTION  oImpMix:Close() CANCEL

  oImpMix:Activate(NIL)

Return nil

/*
// Exporta todos las Tablas del DSN hacia DBF
*/
FUNCTION IMPORT()
  LOCAL cFile,i,U,cLista:="",cDirDp
  LOCAL cDir  :=ALLTRIM(oImpMix:cDir)
  LOCAL aFiles:={}
  LOCAL aPrecios:={"A","B","C","D","E","F","G","H"}
  LOCAL aUnd    :={"U","G","O"}
  LOCAL cId     :="MIXNET",cSql
  LOCAL oData   :=DATASET(cId,"ALL")
 
  oData:Set("cDir",oImpMix:cDir)
  oData:Save()
  oData:End()

// AADD(aFiles,{"DPCTA.DBF"   ,"DPCTA"     ,""})
// AADD(aFiles,{"DPGRU.DBF"   ,"DPGRU"     ,""})
// AADD(aFiles,{"DPALM.DBF"   ,"DPALMACEN" ,""})
// AADD(aFiles,{"MXMARINV.DBF" ,"DPMARCAS"  ,""})
// AADD(aFiles,{"DPVEN.DBF"   ,"DPVENDEDOR",""})
// AADD(aFiles,{"DPINV.DBF"   ,"DPINV"     ,""})
// AADD(aFiles,{"DPCLI.DBF"   ,"DPCLIENTES",""})
// AADD(aFiles,{"DPZONAS.DBF" ,"DPZONAS"   ,""})
// AADD(aFiles,{"DPCLICLA.DBF","DPCLICLA"  ,""})

  DBCLOSEALL()

  IF RIGHT(cDir,1)!="\"
     cDir:=cDir+"\"
  ENDIF

  oImpMix:oDir:VarPut(PADR(cDir,30))
  oImpMix:cDir:=cDir
  cDirDp:=LEFT(cDir,Rat("\",cDir))+"DP\"

  IF !FILE(cDir+"MXCTAINV.DBF")
     MensajeErr("Archivo "+cDir+" MXCTAINV.DBF No existe ")
     RETURN .F.
  ENDIF

  FOR I=1 TO LEN(aFiles)
    cFile:=cDir+aFiles[I,1]
    IF !FILE(cFile)
      cLista:=cLista+IIF(EMPTY(cLista),"",",")+cFile+CRLF
    ENDIF
    aFiles[I,1]:=cFile
    aFiles[I,3]:=BLOQUECOD(aFiles[I,3]) // Proceso Registro por Registro
  NEXT I

  IF !EMPTY(cLista)
     MsgAlert("Archivo(s):"+CRLF+cFile,"No Existe")
     RETURN .F.
  ENDIF

  DBCLOSEALL()
  SET DELE OFF

  // Ejecuta Importar //

  oDp:cMemo:=""

  // EJECUTAR("IMPORTDP",oImpMix:cDsn,aFiles,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,.T.,.F.)

  cSql:=" SET FOREIGN_KEY_CHECKS = 0"
  OpenOdbc(oDp:cDsnData):Execute(cSql)

  IF oImpMix:lInicia

    EJECUTAR("DELETEINV")
    EJECUTAR("DELETECLI")
    EJECUTAR("DELETEPRO")
/*
    SQLDELETE("DPPRECIOS")
    SQLDELETE("DPINVMED")
    SQLDELETE("DPEQUIV")
    SQLDELETE("DPCOMPONENTES")
    SQLDELETE("DPINV")
    SQLDELETE("DPCLIENTES")
    SQLDELETE("DPCLICLA")
    SQLDELETE("DPCLIENTESPER")
    SQLDELETE("DPACTIVIDAD_E")
    SQLDELETE("DPVENDEDOR")
*/
  ENDIF

  oImpMix:oMeterT:SetTotal(10)

  IF oImpMix:lInv

    oImpMix:nTables:=EJECUTAR("IMPORTINVMIX",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                     oImpMix:nTables,oImpMix:lInicia)

  ENDIF

  IF oImpMix:lCxP 

    oImpMix:nTables:=EJECUTAR("IMPORTPROMIX",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                    oImpMix:nTables,oImpMix:lInicia)

  ENDIF

  IF oImpMix:lCxC

      oImpMix:nTables:=EJECUTAR("IMPORTMXCLI",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                      oImpMix:nTables,oImpMix:lInicia)

      oImpMix:nTables:=EJECUTAR("IMPORTCXCMIX",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                      oImpMix:nTables,oImpMix:lInicia)

//      oImpMix:nTables:=EJECUTAR("IMPORTCXC",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
//                      oImpMix:nTables,oImpMix:lInicia)

  ENDIF

  IF oImpMix:lBco   

     oImpMix:nTables:=EJECUTAR("IMPORTBCOMIX",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                      oImpMix:nTables,oImpMix:lInicia)

  ENDIF

  IF oImpMix:lCon 

      oImpMix:nTables:=EJECUTAR("IMPORTCONMIX",oImpMix:cDir,oImpMix:oMeterT,oImpMix:oMeterR,oImpMix:oSayTable,oImpMix:oSayRecord,;
                      oImpMix:nTables,oImpMix:lInicia)


  ENDIF

  oImpMix:oMeterR:SetTotal(100)
  oImpMix:oMeterR:Set(100)
  
  oImpMix:oMeterT:SetTotal(100)
  oImpMix:oMeterT:Set(100)

  cSql:=" SET FOREIGN_KEY_CHECKS = 1"
  OpenOdbc(oDp:cDsnData):Execute(cSql)

RETURN .T.

  oImpMix:DPINV(cDir)
  oImpMix:DPEQUIV(cDir)
  oImpMix:DPCOMPO(cDir)

//oImpMix:DPINV(cDir,"NOEXISTE")
// ? "PRODUCTOS"
  oImpMix:DPCLICLA(cDir)
  oImpMix:DPCLIENTES(cDir)
  oImpMix:DPVENDEDOR(cDir)

//  ? "aqui listo"
//  oImpMix:HacerPrecios(cDir+"DPINV.DBF")

RETURN .T.

FUNCTON TEST(oTable,cTable)
//   ? "TEST DE Import19",oTable,cTable
RETURN NIL

PROCE DPCOMPO(cDir)
  LOCAL cFile:=cDir+"DPCOMP",cCodCli:="",nContar:=0,oTable

  IF COUNT("DPCOMPONENTES")>0
     RETURN .F.
  ENDIF

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
  SET FILTER TO COM_TIPO='C'
  DBGOTOP()

  IF COUNT("DPUNDMED")=0
    oTable:=OpenTable("DPUNDMED",.F.)
    oTable:Append()
    oTable:Replace("UND_CODIGO","UND")
    oTable:Replace("UND_DESCRI","Unidad")
    oTable:Replace("UND_CANUND",1)
    oTable:Commit()
  ENDIF

  oTable :=OpenTable("DPCOMPONENTES",.F.)


  oImpMix:oMeterR:SetTotal(RecCount())
  oImpMix:oSayTable:SetText("Componentes")

  SELE A
  WHILE !A->(EOF())

     nContar++
     oImpMix:oMeterR:Set(nContar)
     oImpMix:oSayRecord:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

     oTable:Append()

     IF COUNT("DPINV","INV_CODIGO"+GetWhere("=",COM_CODIGO))=0
        oImpMix:DPINV(cDir,COM_CODIGO)
     ENDIF

     IF COUNT("DPINV","INV_CODIGO"+GetWhere("=",COM_ARTICU))=0
        oImpMix:DPINV(cDir,COM_ARTICU)
     ENDIF

     oTable:Replace("CPT_CODIGO",COM_CODIGO)
     oTable:Replace("CPT_COMPON",COM_ARTICU)
     oTable:Replace("CPT_CANTID",COM_CANTID)
     oTable:Replace("CPT_UNDMED","UND")
     oTable:Commit()

     // Ahora crearemos el Cargo Representante

     DBSKIP()

  ENDDO

  oTable:End()
  oImpMix:oMeterR:Set(RecCount())

  CLOSE ALL
   
RETURN NIL

PROCE DPEQUIV(cDir)
  LOCAL cFile:=cDir+"DPEQUIV",cCodCli:="",nContar:=0,oTable

  IF COUNT("DPEQUIV")>0
     RETURN .F.
  ENDIF

  oTable :=OpenTable("DPEQUIV",.F.)

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
  SET ORDE TO 1

  oImpMix:oMeterR:SetTotal(RecCount())
  oImpMix:oSayTable:SetText("Equivalencias")

  SELE A
  WHILE !A->(EOF())

     nContar++
     oImpMix:oMeterR:Set(nContar)
     oImpMix:oSayRecord:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

     oTable:Append()
     AEVAL(DBSTRUCT(),{|a,n,uValue|uValue:=FieldGet(n),;
                                  uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                  IIF(oTable:IsDef(FIELDNAME(n),;
                                  oTable:Replace(FIELDNAME(n),uValue)),NIL)})


     oTable:Replace("EQUI_MED","UND") // Ahora Requiere Unidad de Medida

     IF COUNT("DPINV","INV_CODIGO"+GetWhere("=",EQUI_CODIG))=0
        oImpMix:DPINV(cDir,EQUI_CODIG)
     ENDIF

     oTable:Commit()

     DBSKIP()

  ENDDO

  oTable:End()
  oImpMix:oMeterR:Set(RecCount())

  CLOSE ALL
   
RETURN NIL

PROCE DPCLIENTES(cDir)
  LOCAL cFile:=cDir+"DPCLI",cCodCli:="",nContar:=0,oTable,oTableP
  LOCAL cRepres:="Representante Legal"

  IF COUNT("DPCLIENTES")>0
     RETURN .F.
  ENDIF

  oImpMix:BUILDCARGO(cRepres)

  oTable :=OpenTable("DPCLIENTES",.F.)
  oTableP:=OpenTable("DPCLIENTESPER",.F.)

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
//  BROWSE()
  SET ORDE TO 1

  oImpMix:oMeterR:SetTotal(RecCount())
  oImpMix:oSayTable:SetText("Clientes")

  SELE A
  WHILE !A->(EOF())

     nContar++
     oImpMix:oMeterR:Set(nContar)
     oImpMix:oSayRecord:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

     oTable:Append()
     AEVAL(DBSTRUCT(),{|a,n,uValue|uValue:=FieldGet(n),;
                                  uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                  IIF(oTable:IsDef(FIELDNAME(n),;
                                  oTable:Replace(FIELDNAME(n),uValue)),NIL)})

     cCodCli:=ALLTRIM(CLI_CODIGO) 

     IF LEFT(cCodCli,1)="0"
        cCodCli:=REPLI("0",10-LEN(ccodCli))+cCodCli
     ENDIF

     oTable:Replace("CLI_CODCLA" ,oImpMix:BUILDCLACLI(CLI_CLICLA))
     oTable:Replace("CLI_LISTA"  ,oImpMix:BUILDPRECIO(CLI_LISTA ))
     oTable:Replace("CLI_ACTIVI" ,oImpMix:BUILDACTIVI(CLI_ACTIVI))
     oTable:Replace("CLI_PAIS"   ,oDp:cPais)
     oTable:Replace("CLI_ESTADO" ,oDp:cEstado)
     oTable:Replace("CLI_MUNICI" ,oDp:cMunicipio)
     oTable:Replace("CLI_PARROQ" ,oDp:cParroquia)
     oTable:Replace("CLI_CODIGO" ,cCodCli)
     oTable:Replace("CLI_NUMMEM" ,oImpMix:BUILDMEMO(CLI_NUMMEM,CLI_NOMBRE))
     oTable:Commit()

     IF !Empty(CLI_REPRES)
        oTableP:Replace("PDC_CODIGO",cCodCli)
        oTableP:Replace("PDC_CARGO" ,cRepres)
        oTableP:Replace("PDC_PERSON",OEMTOANSI(CLI_REPRES))
        oTableP:Commit()
     ENDIF

     // Ahora crearemos el Cargo Representante

     DBSKIP()

  ENDDO

  oTable:End()
  oTableP:End()
  oImpMix:oMeterR:Set(RecCount())

  CLOSE ALL
   
RETURN NIL

PROCE DPVENDEDOR(cDir)
  LOCAL cFile:=cDir+"DPVEN",cCodVen:="",nContar:=0,oTable

  IF COUNT("DPVENDEDOR")>0
     RETURN .F.
  ENDIF

  oTable :=OpenTable("DPVENDEDOR",.F.)

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
  SET ORDE TO 1

  oImpMix:oMeterR:SetTotal(RecCount())
  oImpMix:oSayTable:SetText("Vendedor")

  SELE A
  WHILE !A->(EOF())

     nContar++
     oImpMix:oMeterR:Set(nContar)
     oImpMix:oSayRecord:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

     oTable:Append()
     AEVAL(DBSTRUCT(),{|a,n,uValue|uValue:=FieldGet(n),;
                                  uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                  IIF(oTable:IsDef(FIELDNAME(n),;
                                  oTable:Replace(FIELDNAME(n),uValue)),NIL)})

     cCodVen:=ALLTRIM(VEN_CODIGO) 

     IF LEFT(cCodVen,1)="0" .OR. ISDIGIT(cCodVen)
        cCodVen:=REPLI("0",6-LEN(cCodVen))+cCodVen
     ENDIF

     oTable:Replace("VEN_CODIGO" ,cCodVen)
     oTable:Commit()

     // Ahora crearemos el Cargo Representante

     DBSKIP()

  ENDDO

  oTable:End()
  oImpMix:oMeterR:Set(RecCount())

  CLOSE ALL
   
RETURN NIL
/*
// Genera Actividad Econ¢mica
*/
FUNCTION BUILDACTIVI(cNombre)
  LOCAL cCodigo,oTable

  IF !Empty(cCodigo)

     cCodigo:=SQLGET("DPACTIVIDAD_E","ACT_CODIGO","ACT_DESCRI"+GETWHERE("=",cNombre))
     IF !EMPTY(cCodigo)
       RETURN cCodigo
     ENDIF

  ENDIF

  cCodigo:=SQLINCREMENTAL("DPACTIVIDAD_E","ACT_CODIGO")
  oTable:=OpenTable("SELECT * FROM DPACTIVIDAD_E",.F.)
  oTable:AppendBlank()
  oTable:Replace("ACT_CODIGO",cCodigo)
  oTable:Replace("ACT_DESCRI",cNombre)
  oTable:Replace("ACT_COMEN1","Desde DP20")
  oTable:Commit()

RETURN cCodigo

/*
// Genera Cargos
*/
FUNCTION BUILDCARGO(cNombre)
  LOCAL oTable

  IF COUNT("DPCARGOS","CAR_CODIGO"+GETWHERE("=",cNombre))>0
      RETURN cNombre
  ENDIF

  oTable:=OpenTable("SELECT * FROM DPCARGOS",.F.)
  oTable:AppendBlank()
  oTable:Replace("CAR_CODIGO",cNombre)
  oTable:Commit()

RETURN cNombre


/*
// Crea los Precios
*/
FUNCTION BUILDPRECIO(cTipPrecio)
  LOCAL oTable

   IF COUNT("DPPRECIOTIP","TPP_CODIGO"+GetWhere("=",cTipPrecio))>0
      RETURN cTipPrecio
   ENDIF

   oTable:=OpenTable("DPPRECIOTIP",.F.)
   oTable:Append()
   oTable:Replace("TPP_CODIGO",aPrecios[I]) 
   oTable:Replace("TPP_DESCRI",aPrecios[I])   
   oTable:Commit()

RETURN cTipPrecio

/*
// Obtiene el Grupo
*/
FUNCTION BUILDCLACLI(cCodCla)
  LOCAL oTable

  IF LEFT(ALLTRIM(cCodCla),1)="0"
     cCodCla:=REPLI("0",6-LEN(ALLTRIM(cCodCla)))+cCodCla
  ENDIF

//  ? cCodCla,"cCodCla"

  IF COUNT("DPCLICLA","CLC_CODIGO"+GETWHERE("=",cCodCla))!=0
     RETURN cCodCla
  ENDIF
     
  IF EMPTY(cCodCla)
     cCodCla:=SQLINCREMENTAL("DPCLICLA","CLC_CODIGO")
  ENDIF

  oTable:=OpenTable("DPCLICLA",.F.)
  oTable:AppendBlank()
  oTable:Replace("CLC_CODIGO",cCodCla)
  oTable:Replace("CLC_DESCRI",cCodCla)
  oTable:Commit()

RETURN cCodCla


PROCE DPINV(cDir,cCodigo)
  LOCAL cFile:=cDir+"MXCTAINV",cFileIva:=cDir+"MXIVA.DBF",cIndex:=cDir+"MXIVA.NTX"
  LOCAL oTable,oTipPre,nContar:=0,I,U,uValue:=0,nUnd,cPrecio
  LOCAL aPrecios:={"A","B","C","D","E","F","G","H"}
  LOCAL aUnd    :={"U","G","O"}

  IF COUNT("DPINV")>0 .AND. Empty(cCodigo)
     RETURN .F.
  ENDIF

  oTable :=OpenTable("DPINV",.F.)
  oTipPre:=OpenTable("DPPRECIOTIP",.F.)

  CLOSE ALL

  SELE A
  USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
  SET ORDE TO 1

  oImpMix:oMeterR:SetTotal(RecCount())
  oImpMix:oSayTable:SetText("Productos DPINV")

  SELE A
  WHILE !A->(EOF()) .OR. !Empty(cCodigo)

     nContar++
     oImpMix:oMeterR:Set(nContar)
     oImpMix:oSayRecord:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

     oTable:Append()
     AEVAL(DBSTRUCT(),{|a,n,uValue|uValue:=FieldGet(n),;
                                  uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                  IIF(oTable:IsDef(FIELDNAME(n),;
                                  oTable:Replace(FIELDNAME(n),uValue)),NIL)})

     oTable:Replace("IVA"   ,IIF(INV_IVA="A","GN","EX"))
//     oTable:Replace("IVA"   ,IIF(INV_IVA="B","RD",oTable:INV_IVA))
     oTable:Replace("GRUPO" ,oImpMix:BUILDGRUPO(oTable:INV_GRUPO))
     oTable:Replace("ESTATUS","A") 

     IF !Empty(cCodigo)
       oTable:Replace("CODART",cCodigo) 
       oTable:Replace("NOMART","Registro Recuperado desde "+cFile)
       oTable:Replace("IVA"   ,"GN")
     ELSE
       oTable:Replace("MEMO",oImpMix:BUILDMEMO(INV_NUMMEM,INV_DESCRI))   
     ENDIF

     oTable:Commit()

     // PREPARACION DE PRECIOS

      FOR I=1 TO IIF(Empty(cCodigo),LEN(aPrecios),0)

          cPrecio:="INV_PVP"+aUnd[1]+aPrecios[I]
          uValue :=FieldGet(FieldPos(cPrecio))

          IF uValue>0 .AND. COUNT("DPPRECIOTIP","TPP_CODIGO"+GetWhere("=",aPrecios[I]))==0
             oTipPre:Append()
             oTipPre:Replace("TPP_CODIGO",aPrecios[I]) 
             oTipPre:Replace("TPP_DESCRI",aPrecios[I])   
             oTipPre:Commit()

          ENDIF 

          // AQUI LAS UNIDADES DE MEDIDA
          oImpMix:UNDMED(INV_UNDMED,1         ,aPrecios[I],uValue,INV_PESO,INV_VOLUME)

          cPrecio:="INV_PVP"+aUnd[2]+aPrecios[I]
          uValue :=FieldGet(FieldPos(cPrecio))
          oImpMix:UNDMED(INV_UNDGRU,INV_CXGRU ,aPrecios[I],uValue,INV_PESO,INV_VOLUME)

          cPrecio:="INV_PVP"+aUnd[3]+aPrecios[I]
          uValue :=FieldGet(FieldPos(cPrecio))
          oImpMix:UNDMED(INV_UNDOTR,INV_CXOTRO,aPrecios[I],uValue,INV_PESO,INV_VOLUME)

          // AHORA LOS PRECIOS

//        ? cPrecio,uValue

        NEXT I

//   NEXT U

     DBSKIP()

     IF !Empty(cCodigo) // Para agregar Productos no Existentes
        EXIT
     ENDIF

  ENDDO

  oTable:End()
  iif(lMeter , oMeterR:Set(RecCount()) , nil )

  oTipPre:End()

  CLOSE ALL
   
RETURN NIL

/*
// Crea Unidad de Medida
*/
FUNCTION UNDMED(cUnd,nCant,cPrecio,nPrecio,nPeso,nVol)
    LOCAL oTable

    // Busca en la Tabla de Unidades de Media
    // ? cUnd,nCant,cPrecio,INV_CODIGO,nPrecio

    IF Empty(cUnd)
       cUnd:="UND"
    ENDIF

    IF EMPTY(nCant)
       nCant:=0
    ENDIF

    IF nPrecio=0 .AND. !Empty(nPeso+nVol)
       RETURN .T.
    ENDIF

    IF !Empty(cUnd) .AND. COUNT("DPUNDMED","UND_CODIGO"+GetWhere("=",cUnd))=0
       oTable:=OpenTable("SELECT * FROM DPUNDMED",.F.)
       oTable:AppendBlank()
       oTable:Replace("UND_CODIGO",cUnd )
       oTable:Replace("UND_DESCRI",cUnd )
       oTable:Replace("UND_CANUND",nCant)
       oTable:Commit()
       oTable:End()
    ENDIF

    IF nPrecio>0 .AND.;
       COUNT("DPPRECIOS","PRE_LISTA" +GetWhere("=",cPrecio   )+;
                    " AND PRE_CODIGO"+GetWhere("=",INV_CODIGO)+;
                    " AND PRE_UNDMED"+GetWhere("=",cUnd      )+;
                    " AND PRE_CODMON"+GetWhere("=","Bs"      ))=0

       oTable:=OpenTable("DPPRECIOS",.F.)
       oTable:Append()
       oTable:Replace("PRE_LISTA" ,cPrecio)
       oTable:Replace("PRE_UTILID",FIELDGET(FIELDPOS("INV_UTIL"+cPrecio)))
       oTable:Replace("PRE_CODIGO",INV_CODIGO)
       oTable:Replace("PRE_PRECIO",nPrecio)
       oTable:Replace("PRE_UNDMED",cUnd)
       oTable:Replace("PRE_CODMON","Bs")
       oTable:Commit()
       oTable:End()
    ENDIF


    IF (nCant=0 .OR. EMPTY(cUnd)) .AND. !Empty(nPeso+nVol)
       RETURN .T.
    ENDIF

    // Busca si la Unidad Medida no Tiene las Cantidad Estandar
    IF COUNT("DPUNDMED","UND_CODIGO"+GetWhere("=",cUnd)+" AND UND_CANUND"+GetWhere("=",nCant))>0
       RETURN .T.
    ENDIF

    // Debe Crear Unidad de Medida Expec¡fica
    IF COUNT("DPINVMED","IME_CODIGO"+GetWhere("=",INV_CODIGO)+" AND IME_UNDMED"+GetWhere("=",cUnd)+" AND IME_CANTID"+GetWhere("=",nCant))>0
       RETURN .T.
    ENDIF

    oTable:=OpenTable("SELECT * FROM DPINVMED",.F.)
    oTable:AppendBlank()
    oTable:Replace("IME_CODIGO",INV_CODIGO )
    oTable:Replace("IME_UNDMED",cUnd       )
    oTable:Replace("IME_COMPRA","S"        )
    oTable:Replace("IME_VENTA" ,"S"        )
    oTable:Replace("IME_CANTID",nCant      )
    oTable:Replace("IME_PESO"  ,nPeso*nCant)
    oTable:Replace("IME_VOLUME",nVol *nCant)

    oTable:Commit()
    oTable:End()

RETURN .T.

/*
// Obtiene el Grupo
*/
FUNCTION BUILDGRUPO(cGrupo)
  LOCAL oTable

  IF Empty(cGrupo)
     cGrupo:=STRZERO("0",LEN(cGrupo))
  ENDIF

  IF COUNT("DPGRU","GRU_CODIGO"+GetWhere("=",cGrupo))=0
     RETURN cGrupo
  ENDIF

  
  oTable:=OpenTable("SELECT * FROM DPGRU",.F.)
  oTable:Append()
  oTable:Replace("GRU_CODIGO",cGrupo)
  oTable:Replace("GRU_DESCRI",cGrupo)
  oTable:End()

RETURN cGrupo

//
// DPCLICLA
//
FUNCTION DPCLICLA(cDir)
   LOCAL cFile:=cDir+"DPCLICLA.DBF",cCodCla

   LOCAL oTable

   IF COUNT("DPCLICLA")>1
      RETURN .T.
   ENDIF

   CLOSE ALL

   oTable:=OpenTable("DPCLICLA",.F.)

   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
   DBGOTOP()

   WHILE !EOF()

     cCodCla:=DPCLICLA->CLI_CLACOD

     IF LEFT(ALLTRIM(cCodCla),1)="0"
        cCodCla:=REPLI("0",6-LEN(ALLTRIM(cCodCla)))+cCodCla
     ENDIF

     IF COUNT("DPCLICLA","CLC_CODIGO"+GETWHERE("=",cCodCla))=0

        oTable:AppendBlank()
        oTable:Replace("CLC_CODIGO",cCodCla)
        oTable:Replace("CLC_DESCRI",ANSITOOEM(DPCLICLA->CLI_CLANOM))
        oTable:Commit()
     ENDIF
     DBSKIP()
   ENDDO

   USE
   oTable:End()

RETURN .T.

FUNCTION HACERPRECIOS(cFile)
   LOCAL aPrecios:={"A","B","C","D","E","F","G","H"},I,U
   LOCAL oTable :=OpenTable("DPPRECIOTIP",.F.)
   LOCAL oUndMed:=OpenTable("DPUNDMED"   ,.F.)
   LOCAL oPrecio:=OpenTable("DPPRECIOS"  ,.F.)
   LOCAL nPrecio,cPrecio,aTipos:={"U","G","O"}
   LOCAL aUndMed:={"UND","GRU","OTR"}

   CLOSE ALL

   FOR I=1 TO LEN(aPrecios)

      IF EMPTY(SQLGET("DPPRECIOTIP","TPP_CODIGO","TPP_CODIGO"+GetWhere("=",aPrecios[I])))
         oTable:Append()
         oTable:Replace("TPP_CODIGO",aPrecios[I]) 
         oTable:Replace("TPP_DESCRI",aPrecios[I])   
         oTable:Commit()
      ENDIF 

   NEXT I

   oTable:End()
   
   // Crea los precios
   USE (cFile) EXCLU VIA "DBFCDX"

   WHILE !Eof()

     // Unidad de Medida
     cUndMed:="UND"
     aUndMed[1]:=cUndMed
     
     IF !Empty(INV_UNDMED)
        cUndMed:=INV_UNDMED
     ENDIF

     IF EMPTY(SQLGET("DPUNDMED","UND_CODIGO","UND_CODIGO"+GetWhere("=",INV_UNDMED)))
        cUndMed:=INV_UNDMED
        oUndMed:Append()
        oUndMed:Replace("UND_CODIGO",INV_UNDMED)
        oUndMed:Replace("UND_DESCRI",INV_UNDMED)
        oUndMed:Replace("UND_CANUND",1         )
        oUndMed:Commit()
     ENDIF

     FOR I=1 TO LEN(aPrecios)

        FOR U=1 TO LEN(aTipos)

          nPrecio:=FieldGet("INV_PVP"+aTipos[U]+aPrecios[I])
          IF nPrecio>0
             oPrecio:Append()
             oPrecio:Replace("PRE_CODIGO",INV_UNDMED)
             oPrecio:Replace("PRE_UNDMED",INV_UNDMED)
             oPrecio:Commit()
          ENDIF

        NEXT U
     NEXT I

     SKIP

   ENDDO
   USE

   oUndMed:End()

RETURN .T.

FUNCTION BUILDMEMO(nNumMem,cDescri)
  LOCAL cAlias:=ALIAS(),cFile,cIndex,oMemo

  DEFAULT cDescri:=""

  IF nNumMem=0
     RETURN 0
  ENDIF

  IF !DPSELECT("DPMEMO")
     cFile:=ALLTRIM(oImpMix:cDir)+"DPMEMO"
     cIndex:=cFile+".CDX"
     SELE G
     USE (cFile) SHARED VIA "DBFCDX" NEW
     SET INDEX TO (cIndex)
  ENDIF

  SET ORDE TO 1
  IF !DBSEEK(nNumMem)
     GO TOP
     LOCATE FOR MEM_NUMERO=nNumMem
  ENDIF

  nNumMem:=SQLGET("DPMEMO","MAX(MEM_NUMERO)")+1
  oMemo:=OpenTable("DPMEMO",.F.)
  oMemo:REPLACE("MEM_NUMERO",nNumMem)
  oMemo:REPLACE("MEM_MEMO"  ,OEMTOANSI(MEM_MEMO ))
  oMemo:REPLACE("MEM_DESCRI",IIF(EMPTY(MEM_DESCRI),OEMTOANSI(cDescri),MEM_DESCRI))
  oMemo:Commit()
  oMemo:End()

  DPSELECT(cAlias)

RETURN nNumMem
// EOF

