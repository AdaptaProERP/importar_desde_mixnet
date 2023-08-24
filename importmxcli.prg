// Programa   : IMPORTMXCLI
// Fecha/Hora : 06/10/2003 16:18:52
// Propósito  : Importar Datos de Clientes DP20
// Creado Por : Juan Navas
// Llamado por: IMPORTDP20
// Aplicación : Todas
// Tabla      : Todas

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lIniciar,cCodCli)
   LOCAL lMeter:=(ValType(oMeterR)="O")
   LOCAL lActividad:=.F. // No crea Actividad
   LOCAL lCliTrans :=.F. // Solo Clientes con Transacciones
   LOCAL cNombre   :=""
   LOCAL oTableD,oTableCar,oTableACT,oTablePRE,oTableCLA

   DEFAULT cDir    :="C:\MIXCLUB\COMP01\",;
           nTables  :=0,;
           lIniciar :=.T.,;
           oDp:cMemo:=""

   rddSetDefault( "DBF" )

   IF lIniciar .AND. !Empty(cCodCli)
      EJECUTAR("DELETECLI")
   ENDIF

   IF Empty(cCodCli)

     CLOSE ALL

     IF(lMeter , oMeterT:Set(nTables++) , NIL)
     IMPORTVEN()

     IF(lMeter , oMeterT:Set(nTables++) , NIL)
     DPCLICLA()

     IF(lMeter , oMeterT:Set(nTables++) , NIL)
     IMPORTACT()

     IF(lMeter , oMeterT:Set(nTables++) , NIL)

   ENDIF

   DPCLIENTES()

   CLOSE ALL

RETURN nTables

PROCE DPCLIENTES(cCodCli)
  LOCAL cFile:=cDir+"MXCTACLI.DBF",nContar:=0,oTable,oTableP,cPrecio:="",cCodCla:="",cCodAct:=""
  LOCAL cRepres:="Representante Legal",nSysR:=0,nRecno:=0,I,uValue,nPos,cWhere

  DEFAULT cCodCli:=""

  BUILDCARGO(cRepres)
//  oTable :=OpenTable("SELECT CLI_CODIGO,CLI_NOMBRE,CLI_CODCLA,CLI_LISTA,CLI_ACTIVI FROM DPCLIENTES", .F. )
//  oTableP:=OpenTable("DPCLIENTESPER" , .F. )

  CLOSE ALL
  IF !FILE(cFile)
     MsgMemo("Archivo "+cFile+" no Existe")
     RETURN .F.
  ENDIF

  SELE A
  USE (cFile) EXCLU NEW ALIAS "DPCLI"
  SET FILTER TO !DELETED()

  IF !Empty(cCodCli)

    SET FILTER TO !DELETED() .AND. ALLTRIM(CODCLI)==ALLTRIM(cCodCli)

  ELSE

    SET FILTER TO !DELETED

    IF "CLUB"$cFile 
      SET FILTER TO !DELETED() .AND. ALLTRIM(A->GRUPO)="01"
    ENDIF

    GO TOP

  ENDIF

  IF lMeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Clientes")
  ENDIF

  nContar:=0
  oTableP:=OpenTable("SELECT * FROM DPCLIENTESPER",.F.) // INSERTINTO("DPCLIENTESPER")
  oTableP:lAuditar:=.F.

  oTable :=OpenTable("SELECT * FROM DPCLIENTES"   ,.F.) // INSERTINTO("DPCLIENTES")
  oTable:lAuditar:=.F.

  SELECT DPCLI

/*
 ? "AQUI",ALIAS(),RECCOUNT()
VIEWARRAY(DBSTRUCT())

// A->(BROWSE())
 RETURN .T.
*/

  GO TOP

  WHILE !DPCLI->(EOF())

     SELECT DPCLI

     IF "CLUB"$cFile .AND. !ALLTRIM(A->GRUPO)="01"
       SKIP
       LOOP
     ENDIF

     // ? CLI_CODIGO

     nContar++

     IF lMeter

        oMeterR:Set(nContar)
        oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+CODCLI)

     ELSE

       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+CODCLI)

       IF nSysR++>10
         nSysR:=0
         SysRefresh(.T.)
       ENDIF

     ENDIF

//     IF !ISDOCCLI(DPCLI->CODCLI)
//        DPCLI->(DBSKIP())
//        LOOP
//     ENDIF
//     oTable:Append()

     cCodCli:=ALLTRIM(CODCLI) 

     IF ISDIGIT(LEFT(cCodCli,1))
        cCodCli:=REPLI("0",10-LEN(ccodCli))+cCodCli
     ENDIF

     cWhere:="CLI_CODIGO"+GetWhere("=",cCodCli)

     IF ISSQLFIND("DPCLIENTES",cWhere)

        oDp:cMemo:=oDp:cMemo+;
                   IIF( Empty(oDp:cMemo) , "" , CRLF )+;
                   "Código de Cliente "+cCodCli+" ya Existe"

        DPCLI->(DBSKIP())

        LOOP

     ENDIF

     cPrecio:=BUILDPRECIO(TARIFA)
     cCodCla:=BUILDCLACLI(GRUPO)
     cCodAct:=DPCLI->CODACTI // BUILDACTIVI(DPCLI->CODACTI)

     oTable:AppendBlank()
     oTable:Replace("CLI_CODIGO"  ,cCodCli)
     oTable:Replace("CLI_SITUAC"  ,IF(ACTIVO,"A","I"))
     oTable:Replace("CLI_NOMBRE"  ,NOMCLI )
     oTable:Replace("CLI_DIR1  "  ,DIREC1 )
     oTable:Replace("CLI_DIR2  "  ,DIREC2 )
     oTable:Replace("CLI_DIR3  "  ,DIREC3 )
     oTable:Replace("CLI_DIR4  "  ,DIREC4 )
     oTable:Replace("CLI_TEL1  "  ,TLF1   )
     oTable:Replace("CLI_TEL2  "  ,TLF2   )
     oTable:Replace("CLI_TEL6  "  ,FAX    )
     oTable:Replace("CLI_LIMITE"  ,LIM_CRE)
     oTable:Replace("CLI_COMEN1"  ,OBSERVA)
     oTable:Replace("CLI_DESCUE"  ,DESCUENTO)
     oTable:Replace("CLI_RIF"     ,CIF      )
     oTable:Replace("CLI_DIAS"    ,DIA_CRE  )
     oTable:Replace("CLI_NIT"     ,NIT      )
     oTable:Replace("CLI_EMAIL"   ,EMAIL    )
     oTable:Replace("CLI_FECHA"   ,FECHAING )

     oTable:Replace("CLI_CODCLA" ,cCodCla)
     oTable:Replace("CLI_LISTA"  ,cPrecio)
     oTable:Replace("CLI_ACTIVI" ,cCodAct)

     oTable:Replace("CLI_PAIS"   ,oDp:cPais     )
     oTable:Replace("CLI_ESTADO" ,oDp:cEstado   )
     oTable:Replace("CLI_MUNICI" ,oDp:cMunicipio)
     oTable:Replace("CLI_PARROQ" ,oDp:cParroquia)

     oTable:lAuditar:=.F.
     oTable:Commit("")

     IF !Empty(CONTACTO) 
        oTableP:Replace("PDC_CODIGO",cCodCli)
        oTableP:Replace("PDC_CARGO" ,cRepres)
        oTableP:Replace("PDC_PERSON",OEMTOANSI(CONTACTO))
        oTableP:Commit()
     ENDIF

     // Ahora crearemos el Cargo Representante

     DPCLI->(DBSKIP())

     IF RECNO()>5
//        EXIT
     ENDIF
 
  ENDDO

   oTable:EXECUTE([UPDATE dpclientes SET CLI_SITUAC="A",CLI_TIPPER=IF(LEFT(CLI_RIF,1)="J","J","N")])
   oTable:EXECUTE([UPDATE dpclientes SET CLI_TIPPER=IF(LEFT(CLI_RIF,1)="G","G",CLI_TIPPER)])

  oTable:End()
  oTableP:End()

  IIF( lMeter , oMeterR:Set(RecCount()) , NIL )

  CLOSE ALL
    
RETURN NIL

/*
// Genera Actividad Econ¢mica
*/
FUNCTION BUILDACTIVI(cCodigo)
  LOCAL oTable,cWhere,nLen

  IF Empty(cCodigo)
    cCodigo:=STRZERO(1,6)
  ENDIF

  cWhere:="ACT_CODIGO"+GetWhere("=",cCodigo)

  IF ISSQLFIND("DPACTIVIDAD_E",cWhere) //  "ACT_CODIGO",cCodigo)
     RETURN cCodigo
  ENDIF

  // cCodigo:=SQLINCREMENTAL("DPACTIVIDAD_E","ACT_CODIGO",[LEFT(ACT_CODIGO,1)="0"],NIL,NIL,.T.,6)

  DEFAULT oTableACT:=OpenTable("SELECT * FROM DPACTIVIDAD_E",.F.)

  oTableACT:AppendBlank()
  oTableACT:Replace("ACT_CODIGO",cCodigo)
  oTableACT:Replace("ACT_DESCRI",cNombre)
  oTableACT:Replace("ACT_COMEN1","Desde MIXNET")
  oTableACT:lAuditar:=.F.
  oTableACT:Commit()
//  oTable:End()

RETURN cCodigo

/*
// Genera Cargos
*/
FUNCTION BUILDCARGO(cNombre)
//  LOCAL oTable

  IF COUNT("DPCARGOS","CAR_CODIGO"+GETWHERE("=",cNombre))>0
      RETURN cNombre
  ENDIF

  DEFAULT oTableCar:=OpenTable("SELECT * FROM DPCARGOS",.F.)

  oTableCar:AppendBlank()
  oTableCar:Replace("CAR_CODIGO",cNombre)
  oTableCar:Commit()
  oTableCar:lAuditar:=.F.

//oTable:End()

RETURN cNombre

/*
// Obtiene el Grupo
*/
FUNCTION BUILDCLACLI(cCodCla)
  LOCAL oTable,cNomCla:="Indefinida",cWhere

  IF ISDIGIT(LEFT(ALLTRIM(cCodCla),1))
     cCodCla:=REPLI("0",6-LEN(ALLTRIM(cCodCla)))+cCodCla
  ENDIF

  IF Empty(cCodCla)
    cCodCla:=STRZERO(1,6)
  ENDIF

  cCodCla:=ALLTRIM(cCodCla)
  cWhere :="CLC_CODIGO"+GetWhere("=",cCodCla)
 

  IF ISSQLFIND("DPCLICLA",cWhere) // "CLC_CODIGO",cCodCla)
     RETURN cCodCla
  ENDIF
    
  DEFAULT oTableCla:=OpenTable("DPCLICLA",.F.)

  oTableCla:AppendBlank()
  oTableCla:Replace("CLC_CODIGO",cCodCla)
  oTableCla:Replace("CLC_DESCRI",cNomCla)
  oTableCla:lAuditar:=.T.
  oTableCla:Commit()

//   oTable:End()

RETURN cCodCla

//
// DPCLICLA
//
FUNCTION DPCLICLA()
   LOCAL cFile:=cDir+"MXGRUCLI.DBF",cCodCla

   LOCAL oTable

   CLOSE ALL

   oTable:=INSERTINTO("DPCLICLA")

   SELE A
   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
   DBGOTOP()

   WHILE !A->(EOF())

     cCodCla:=A->GRUCLI

     IF ISDIGIT(LEFT(ALLTRIM(cCodCla),1))
        cCodCla:=REPLI("0",6-LEN(ALLTRIM(cCodCla)))+cCodCla
     ENDIF

     cCodCla:=ALLTRIM(cCodCla)

     IF !ALLTRIM(SQLGET("DPCLICLA","CLC_CODIGO","CLC_CODIGO"+GETWHERE("=",cCodCla)))==cCodCla
        oTable:Replace("CLC_CODIGO",cCodCla)
        oTable:Replace("CLC_DESCRI",ANSITOOEM(A->NOMGRUCLI))
        oTable:Commit()
     ENDIF

     A->(DBSKIP())

   ENDDO

   USE
   oTable:End()

RETURN .T.

FUNCTION BUILDMEMO(nNumMem,cDescri)
  LOCAL cAlias:=ALIAS(),cFile,cIndex,oMemo

  DEFAULT cDescri:=""

  IF nNumMem=0 
     RETURN 0
  ENDIF

  IF !DPSELECT("DPMEMO")
     cFile:=ALLTRIM(cDir)+"DPMEMO"
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

  IF Empty(MEM_MEMO)
    DPSELECT(cAlias)
    RETURN .F.
  ENDIF

  nNumMem:=SQLINCREMENTAL("DPMEMO","MEM_NUMERO")
  oMemo:=OpenTable("DPMEMO",.F.)
  oMemo:REPLACE("MEM_NUMERO",nNumMem)
  oMemo:REPLACE("MEM_MEMO"  ,OEMTOANSI(MEM_MEMO ))
  oMemo:REPLACE("MEM_DESCRI",IIF(EMPTY(MEM_DESCRI),OEMTOANSI(cDescri),MEM_DESCRI))
  oMemo:Commit()
  oMemo:End()

  DPSELECT(cAlias)

RETURN nNumMem

/*
// Crea los Precios
*/
FUNCTION BUILDPRECIO(cTipPrecio)
  //LOCAL oTable
  
   cTipPrecio:=IIF(Empty(cTipPrecio),"A",cTipPrecio)

   IF ISSQLGET("DPPRECIOTIP","TPP_CODIGO",cTipPrecio)
      RETURN cTipPrecio
   ENDIF

   DEFAULT oTablePRE:=OpenTable("DPPRECIOTIP",.F.)

   oTablePRE:Append()
   oTablePRE:Replace("TPP_CODIGO",cTipPrecio) 
   oTablePRE:Replace("TPP_DESCRI",cTipPrecio)   
   oTablePRE:Commit("")
// oTable:End()

RETURN cTipPrecio

FUNCTION CLIREPITE()
  LOCAL nRecno:=RECNO(),cCodCli
  LOCAL aData:={}

  AEVAL( Dbstruct(), {|a,n| AADD(aData,FieldGet(n)) } )

  DBGOBOTTOM()
  cCodCli:=STRZERO(VAL(CLI_CODIGO)+1,8)
  APPEND BLANK
  BLOC()
  AEVAL( aData ,{|a,n| FieldPut(n,a) } )

  REPLACE CLI_CODIGO WITH cCodCli
 
  DBGOTO(nRecno)

RETURN cCodCli

//
// Importar Vendedores
//
FUNCTION IMPORTVENOLD()
   LOCAL cFile:=cDir+"MXCTAVDD.DBF",cCodVen,nContar:=0
   LOCAL cWhere
   LOCAL oTable

   CLOSE ALL

   oTable:=INSERTINTO("DPVENDEDOR")

   SELE A
   USE (ALLTRIM(cFile)) SHARED NEW ALIAS "DPVEN"
   DBGOTOP()

   IF lMeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("Vendedor")
   ENDIF

   WHILE !DPVEN->(EOF())

     cCodVen:=DPVEN->CODVEN
     nContar++

     IF lMeter

       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(DPVEN->(RECCOUNT()))+" "+cCodVen)

     ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodVen)

     ENDIF

     IF ALLDIGIT(cCodVen)
        cCodVen:=STRZERO(VAL(cCodVen),LEN(cCodVen))
     ENDIF

     cWhere:="VEN_CODIGO"+GetWhere("=",cCodVen)

     IF !ISSQLFIND("DPVENDEDOR",cWhere)

        oTable:Replace("VEN_CODIGO",cCodVen)
        oTable:Replace("VEN_NOMBRE",ANSITOOEM(DPVEN->NOMVEN))
        oTable:Replace("VEN_PORVEN",COMISION)

        oTable:Commit()

     ENDIF

     DPVEN->(DBSKIP())

   ENDDO

   USE
   oTable:End()

RETURN .T.

/*
// Busca si el Cliente Tiene Transacciones
*/
FUNCTION ISDOCCLI(cCodCli)
   LOCAL lResp:=.F.,aAlias:={"C","D","E","F"},I

   // Sólo Clientes con Transacciones
   IF !lCliTrans 
      RETURN .T.
   ENDIF

   IF !DPSELECT("DPFAC")

      SELE C
      USE (cDir+"DPFAC.DBF") SHARED ALIAS "DPFAC"
      SET ORDE TO 2

      SELE D
      USE (cDir+"DPCOTZ.DBF") SHARED ALIAS "DPCOTZ"
      SET ORDE TO 2

      SELE E
      USE (cDir+"DPNOTAE.DBF") SHARED ALIAS "DPNOTAE"
      SET ORDE TO 2

      SELE F
      USE (cDir+"DPPEDV.DBF") SHARED ALIAS "DPPEDV"
      SET ORDE TO 2

   ENDIF

   FOR I=1 TO LEN(aAlias)
      IF !lResp .AND. (aAlias[I])->(DBSEEK(cCodCli,.F.))
         lResp:=.T.
      ENDIF
   NEXT I
  
   SELECT DPCLI

RETURN lResp

//
// Importar Actividad Económica
//
FUNCTION IMPORTACT()
   LOCAL cFile:=cDir+"MXACTCLI.DBF",cCodAct,nContar:=0

   LOCAL oTable

   IF !FILE(cFile)
      MsgMemo("Archivo "+cFile+"no Existe")
      RETURN .F.
   ENDIF

   CLOSE ALL

   SQLDELETE("DPACTIVIDAD_E")

   oTable:=INSERTINTO("DPACTIVIDAD_E")

   SELE A
   USE (ALLTRIM(cFile)) EXCLU NEW ALIAS "DPACTECO"
   DBGOTOP()

   IF lMeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("Actividad Económica")
   ENDIF

   WHILE !DPACTECO->(EOF())

     cCodAct:=DPACTECO->CODACTI
     nContar++

     IF lMeter

       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(DPACTECO->(RECCOUNT()))+" "+cCodAct)

     ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodAct)

     ENDIF

//     IF ALLDIGIT(cCodAct)
//        cCodAct:=STRZERO(VAL(cCodAct),LEN(cCodAct))
//     ENDIF
//     IF !ISSQLGET("DPACTIVIDAD_E","ACT_CODIGO",cCodAct)

        oTable:Replace("ACT_CODIGO",cCodAct)
        oTable:Replace("ACT_DESCRI",ANSITOOEM(DPACTECO->NOMACTI))

        oTable:Commit()

//     ENDIF

     DPACTECO->(DBSKIP())

   ENDDO

   USE

   oTable:End()

RETURN .T.

FUNCTION IMPORTVEN()
  LOCAL nContar:=0,oTable,cCodVen
  LOCAL cFile:=cDir+"MXCTAVDD.DBF"

  IF COUNT("DPVENDEDOR")>0
     RETURN .F.
  ENDIF

  IF !FILE(cFile)
     MsgMemo(cFile)
     RETURN .F.
  ENDIF

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 

  DBGOTOP()

  oTable :=OpenTable("DPVENDEDOR",.F.)
  oTable:SetInsert(200)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Cuentas")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     cCodVen:=DPVEN->CODVEN

     IF EMPTY(cCodVen)
        A->(DBSKIP())
        LOOP
     ENDIF

     IF ALLDIGIT(cCodVen)
        cCodVen:=STRZERO(VAL(cCodVen),LEN(cCodVen))
     ENDIF

     nContar++

     IF lmeter
       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ELSE
       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ENDIF

     oTable:ReplaceSpeed("VEN_CODIGO",cCodVen   )
     oTable:ReplaceSpeed("VEN_NOMBRE",ANSITOOEM(DPVEN->NOMVEN))
     oTable:ReplaceSpeed("VEN_PORVEN",COMISION)
     oTable:CommitSpeed(.F.)

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

   
RETURN NIL

// EOF

