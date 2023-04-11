// Programa   : IMPORTPROMIX
// Fecha/Hora : 06/10/2003 16:18:52
// Propósito  : Importar Datos de Proveedores DP20
// Creado Por : Miguel Figueroa
// Llamado por: IMPORTDP20
// Aplicación : Todas
// Tabla      : Todas

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lIniciar)
   LOCAL oDb:=OpenOdbc(oDp:cDsnData),cSql
   LOCAL lMeter:=(ValType(oMeterR)="O")

   DEFAULT cDir:="C:\MIXCLUB\COMP01\",;
           nTables  :=0    ,;
           lIniciar :=.F.  ,;
           oDp:cMemo:=""

   IF lIniciar
      EJECUTAR("DELETEPRO")
   ENDIF

   CLOSE ALL

   oDb:=OpenOdbc(oDp:cDsnData)
   cSql:=" SET FOREIGN_KEY_CHECKS = 0"
   oDb:Execute(cSql)

   SQLDELETE("DPACTIVIDAD_E","LEFT(ACT_CODIGO,1)"+GetWhere("=","N"))

   IF(lMeter , oMeterT:Set(nTables++) , NIL)
   DPPROCLA()

   IF(lMeter , oMeterT:Set(nTables++) , NIL)
   DPPROVEEDOR()

   oDb:=OpenOdbc(oDp:cDsnData)
   cSql:=" SET FOREIGN_KEY_CHECKS = 1"
   oDb:Execute(cSql)


   CLOSE ALL

RETURN nTables

PROCE DPPROVEEDOR(cCodpro)
  LOCAL cFile:=cDir+"MXCTAPRO",nContar:=0,oTable,oTableP,cPrecio:="",cCodCla:="",cCodAct:=""
  LOCAL cRepres:="Representante Legal",nSysR:=0,nRecno:=0,I,uValue,nPos,nLen
  LOCAL cWhere

  DEFAULT cCodpro:=""

  BUILDCARGO(cRepres)

  oTable :=OpenTable("SELECT * FROM DPPROVEEDOR ", .F. )
  nLen   :=LEN(oTable:PRO_CODIGO)

  oTableP:=OpenTable("DPPROVEEDORPER" , .F. )

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
//  BROWSE()
  SET FILTER TO !DELETED()
  SET ORDE TO 0

  IF lMeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Actividad Económica")
  ENDIF

  // REVISAR 

  SELE A

// BROWSE()
// RETURN 

  GO TOP
  WHILE !A->(EOF())

     nContar++

     IF lMeter

      oMeterR:Set(nContar)
      oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))

    ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+CODCLI)

    ENDIF

    // Crear Actividad Económica
    // BUILDACTIVI(A->CODACTI)

    A->(DBSKIP())

  ENDDO

  GO TOP

  IF lMeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Proveedor")
  ENDIF

  nContar:=0

  SELE A

  WHILE !A->(EOF())

     nContar++

     IF lMeter

        oMeterR:Set(nContar)
        oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+A->CODCLI)

     ELSE

       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+A->CODCLI)

       IF nSysR++>10
         nSysR:=0
         SysRefresh(.T.)
       ENDIF

     ENDIF

     oTable:AppendBlank()
/*
     AEVAL(DBSTRUCT(),{|a,n,uValue,cField|uValue:=FieldGet(n),;
                                   uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                   cField:=FieldName(n),;
                                   cField:=STRTRAN(cField,"CLI_","PRO_"),;
                                   IIF(oTable:IsDef(cField,;
                                   oTable:Replace(cField,uValue)),NIL)})
*/

     cCodpro:=ALLTRIM(A->CODCLI) 

     IF ALLDIGIT(cCodpro)
        // cCodpro:=REPLI("0",10-LEN(cCodpro))+cCodpro
        cCodPro:=STRZERO(VAL(cCodPro) ,nLen )
             
     ENDIF

     cWhere:="PRO_CODIGO"+GetWhere("=",cCodpro)

     IF ISSQLFIND("DPPROVEEDOR",cWhere)

        oDp:cMemo:=oDp:cMemo+;
                   IIF( Empty(oDp:cMemo) , "" , CRLF )+;
                   "Código de Proveedor "+A->CODCLI+" ya Existe"

        A->(DBSKIP())
        LOOP

     ENDIF

     cCodCla:=STRZERO(1,6) // BUILDCLAPRO(A->CODCLI)
     cCodAct:=STRZERO(1,6) // BUILDACTIVI(A->CODCLI)

     oTable:Replace("PRO_CODIGO" ,cCodPro)
     oTable:Replace("PRO_CODCLA" ,cCodCla)
     oTable:Replace("PRO_ACTIVI" ,cCodAct)
     oTable:Replace("PRO_PAIS"   ,oDp:cPais )
     oTable:Replace("PRO_ESTADO" ,oDp:cEstado)
     oTable:Replace("PRO_MUNICI" ,oDp:cMunicipio)
     oTable:Replace("PRO_PARROQ" ,oDp:cParroquia)
     oTable:Replace("PRO_NOMBRE" ,A->NOMCLI)
     oTable:Replace("PRO_RIF"   ,A->CIF)
     oTable:Replace("PRO_DIR1"  ,A->DIREC1)
     oTable:Replace("PRO_DIR2"  ,A->DIREC2)
     oTable:Replace("PRO_DIR3"  ,A->DIREC3)
     oTable:Replace("PRO_DIR4"  ,A->DIREC4)
     oTable:Replace("PRO_TEL1"  ,A->TLF1)
     oTable:Replace("PRO_TEL2"  ,A->TLF2)
     oTable:Replace("PRO_TEL6"  ,A->FAX)
     oTable:Replace("PRO_LIMITE",A->LIM_CRE)
     oTable:Replace("PRO_DIAVE" ,A->DIA_CRE)
     oTable:Replace("PRO_DESCUE",A->DESCUENTO)
     oTable:Replace("PRO_NIT"   ,A->NIT)
     oTable:Replace("PRO_TIPO"  ,"Proveedor")
     oTable:Replace("PRO_SITUAC"  ,"Activo")
     oTable:Replace("PRO_EMAIL"  ,A->EMAIL)


     oTable:Commit("")

 
     IF !Empty(A->CONTACTO) 
        oTableP:Append()
        oTableP:Replace("PDP_CODIGO",cCodpro)
        oTableP:Replace("PDP_CARGO" ,cRepres)
        oTableP:Replace("PDP_PERSON",OEMTOANSI(A->CONTACTO))
        oTableP:Commit()
     ENDIF

     // Ahora crearemos el Cargo Representante

     A->(DBSKIP())

  ENDDO

   oTable:EXECUTE([UPDATE dpproveedor SET PRO_SITUAC="A",PRO_TIPPER=IF(LEFT(PRO_RIF,1)="J","J","N")])
   oTable:EXECUTE([UPDATE dpproveedor SET PRO_TIPPER=IF(LEFT(PRO_RIF,1)="G","G",PRO_TIPPER)])

  oTable:End()
  oTableP:End()

  IIF( lMeter , oMeterR:Set(RecCount()) , NIL )

  CLOSE ALL

    
RETURN NIL

/*
// Genera Actividad Econ¢mica
*/
FUNCTION BUILDACTIVI(cNombre)
  LOCAL cCodigo,oTable

  IF !Empty(cNombre)

     cCodigo:=SQLGET("DPACTIVIDAD_E","ACT_CODIGO","ACT_DESCRI"+GETWHERE("=",cNombre))

     IF !EMPTY(cCodigo)
       RETURN cCodigo
     ENDIF

  ELSE

     cNombre:="Indefinido"

  ENDIF

  cCodigo:=SQLGET("DPACTIVIDAD_E","ACT_CODIGO","ACT_DESCRI"+GetWhere("=",cNombre))

  IF !Empty(cCodigo)
      RETURN cCodigo
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
// Obtiene el Grupo
*/
FUNCTION BUILDCLAPRO(cCodCla)
  LOCAL oTable

  cCodCla:=A->CODACTI

  IF Empty(cCodCla)
    cCodCla:="000001"
    cNombre:="Creado Automaticamente por DataPro"
  ENDIF

  cCodCla:=ALLTRIM(cCodCla)
  

  IF ALLTRIM(SQLGET("DPPROCLA","CLP_CODIGO","CLP_CODIGO"+GETWHERE("=",cCodCla)))==cCodCla
     RETURN cCodCla
  ENDIF
    
  oTable :=OpenTable("DPPROCLA",.F.)
  oTable:AppendBlank()
  oTable:Replace("CLP_CODIGO",cCodCla)
  oTable:Replace("CLP_DESCRI",cNombre)
  oTable:Replace("CLP_MEMO"  ,"Desde DP20")

  oTable:Commit()

RETURN cCodCla

//
// DPPROCLA
//
FUNCTION DPPROCLA()
   LOCAL cFile:=cDir+"MXGRUPRO.DBF",cCodCla

   LOCAL oTable

   CLOSE ALL

   oTable:=OpenTable("DPPROCLA",.F.)

   SELE A
   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 

   DBGOTOP()

   WHILE !A->(EOF())

     cCodCla:=A->GRUCLI

     IF !ALLTRIM(SQLGET("DPPROCLA","CLP_CODIGO","CLP_CODIGO"+GETWHERE("=",cCodCla)))==cCodCla
        oTable:AppendBlank()
        oTable:Replace("CLP_CODIGO",cCodCla)
        oTable:Replace("CLP_DESCRI",ANSITOOEM(A->NOMGRUCLI))
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
  LOCAL oTable
  
   cTipPrecio:=IIF(Empty(cTipPrecio),"A",cTipPrecio)

   IF SQLGET("DPPRECIOTIP","TPP_CODIGO","TPP_CODIGO"+GetWhere("=",cTipPrecio))=cTipPrecio
      RETURN cTipPrecio
   ENDIF

   oTable:=OpenTable("DPPRECIOTIP",.F.)
   oTable:Append()
   oTable:Replace("TPP_CODIGO",cTipPrecio) 
   oTable:Replace("TPP_DESCRI",cTipPrecio)   
   oTable:Commit()

RETURN cTipPrecio

FUNCTION PROREPITE()
  LOCAL nRecno:=RECNO(),cCodpro
  LOCAL aData:={}

  AEVAL( Dbstruct(), {|a,n| AADD(aData,FieldGet(n)) } )

  DBGOBOTTOM()
  cCodpro:=STRZERO(VAL(PRO_CODIGO)+1,8)
  APPEND BLANK
  BLOC()
  AEVAL( aData ,{|a,n| FieldPut(n,a) } )

  REPLACE PRO_CODIGO WITH cCodpro
 
  DBGOTO(nRecno)

RETURN cCodpro


// EOF


