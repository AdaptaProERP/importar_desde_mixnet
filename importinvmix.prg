// Programa   : IMPORTINVMIX
// Fecha/Hora : 04/03/2006 10:18:45
// Prop¢sito  : Importar Inventarios desde DP20
// Creado Por : Miguel Figueroa
// Llamado por: IMPORTDP
// Aplicaci¢n : Def
// Tabla      : 

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lInicia)

   LOCAL lMeter:=(ValType(oMeterR)="O")

   DEFAULT cDir     :="C:\MIXNET\",;
           lInicia  :=.F.,;
           oDp:cMemo:=""

   rddSetDefault( "DBF" )

oDp:lTracer:=.F.

DPINV()
// SQLDELETE("DPGRU")
// DPGRU()

// DPMARCAS()
RETURN .T.


oDp:lTracer:=.T.


   IF lInicia

      EJECUTAR("DELETEINV")
      SQLDELETE("DPIVATIP")
      SQLDELETE("DPPRECIOTIP")
      SQLDELETE("DPMOVINV")
      SQLDELETE("DPPRECIOS")
      SQLDELETE("DPINVMED")
      SQLDELETE("DPEQUIV")
      SQLDELETE("DPCOMPONENTES")
      SQLDELETE("DPINV")
      SQLDELETE("DPGRU")

EJECUTAR("DPDATACREA",.T.)

   ENDIF

   DPGRU()
   IF(lMeter , oMeterT:Set(nTables++) , NIL)
  
   DPMARCAS()
   IF(lMeter , oMeterT:Set(nTables++) , NIL)

   CLOSE ALL

   DPINV()
   IF(lMeter , oMeterT:Set(nTables++) , NIL)
/*
   DPEQUIV(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)


   DPCOMPO(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)

   DPALM()
   IF(lMeter , oMeterT:Set(nTables++) , NIL)

*/
   CLOSE ALL

RETURN nTables

PROCE DPCOMPO(cDir)
  LOCAL cFile:=cDir+"DPCOMP",cCodCli:="",nContar:=0,oTable

  IF COUNT("DPCOMPONENTES")>0
     RETURN .F.
  ENDIF

  BuildUndMed("UND") // Standar DP20

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 
  SET FILTER TO COM_TIPO='C'

  DBGOTOP()

  oTable :=OpenTable("DPCOMPONENTES",.F.)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Componentes")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     IF EMPTY(A->COM_CODIGO)
        A->(DBSKIP())
        LOOP
     ENDIF

     nContar++
     IF lmeter
       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ELSE
       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ENDIF

     oTable:Append()
     DPINV(COM_CODIGO)
     DPINV(COM_ARTICU)
/*
     IF COUNT("DPINV","INV_CODIGO"+GetWhere("=",COM_CODIGO))=0
        DPINV(COM_CODIGO)
     ENDIF

     IF COUNT("DPINV","INV_CODIGO"+GetWhere("=",COM_ARTICU))=0
        DPINV(COM_ARTICU)
     ENDIF
*/
     oTable:Replace("CPT_CODIGO",COM_CODIGO)
     oTable:Replace("CPT_COMPON",COM_ARTICU)
     oTable:Replace("CPT_CANTID",COM_CANTID)
     oTable:Replace("CPT_UNDMED","UND")
     oTable:Commit()

     // Ahora crearemos el Cargo Representante

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL
   
RETURN NIL

PROCE DPEQUIV(cDir)
 
RETURN NIL

/*
// Crea los Precios
*/
FUNCTION BUILDPRECIO(cTipPrecio)
  LOCAL oTable

  IF ISSQLGET("DPPRECIOTIP","TPP_CODIGO",cTipPrecio)
     RETURN cTipPrecio
  ENDIF

  oTable:=OpenTable("DPPRECIOTIP",.F.)
  oTable:Append()
  oTable:Replace("TPP_CODIGO",aPrecios[I]) 
  oTable:Replace("TPP_DESCRI",aPrecios[I])   
  oTable:Commit(NIL,.F.)
  oTable:End()

RETURN cTipPrecio

PROCE DPINV(cCodigo)
  LOCAL cFile:=cDir+"MXCTAINV.DBF"
  LOCAL cFileIva:=cDir+"MXIVA.DBF",cIndex:=cDir+"MXIVA.CDX"
  LOCAL oTable,oTipPre,nContar:=0,I,U,uValue:=0,nUnd,cPrecio,nCuantos:=0
  LOCAL aPrecios:={"A","B","C","D","E","F","G","H"},bWhile:={||.T.}
  LOCAL aUnd    :={"U","G","O"}
  LOCAL cAlias  :=ALIAS(),cCodInv

//  IF Empty(cCodigo) // .AND. COUNT("DPINV")>0 
//     RETURN .F.
//  ENDIF

  DPGRU()

  IF !FILE(cFile)
     ? "NO EXISTE "+cFile
     RETURN .T.
  ENDIF

  IF !Empty(cCodigo) .AND. ALLTRIM(SQLGET("DPINV","INV_CODIGO","INV_CODIGO"+getWhere("=",cCodigo)))==ALLTRIM(cCodigo)
     RETURN cCodigo
  ENDIF

  oTipPre:=OpenTable("DPPRECIOTIP",.F.)

  SELE C

  USE (ALLTRIM(cFile)) SHARED ALIAS "DPINV" 

 BROWSE()

  DBGOTOP()

  IF !Empty(cCodigo)

    LOCATE FOR CODART=cCodigo

    IF !FOUND()

       APPEND BLANK
       REPLACE CODART WITH cCodigo,;
               NOMART WITH "Recuperado por DpAdmWin Migración",;
               IVA    WITH "A",;
               GRUPO  WITH BuildGrupo()
       GO TOP
       LOCATE FOR CODART=cCodigo

    ENDIF
    
    bWhile:={||DPINV->CODART=cCodigo}
   
  ENDIF

  IF lMeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Productos")
  ENDIF

//  oTable :=INSERTINTO("DPINV")
  oTable:=OpenTable("SELECT * FROM DPINV",.F.)

  SELE DPINV

  WHILE !DPINV->(EOF()) .AND. EVAL(bWhile)

     nContar++
     nCuantos++

     IF "TTA"$oTable:ClassName() .AND. nCuantos>200 

        oTable:End()
        CLOSEDSN(oDp:cDsnData)
        oTable :=OpenTable("DPINV",.F.)
        oTable:lOnly:=.F.
        nCuantos:=0

     ENDIF
    
     cCodInv:=UPPE(DPINV->CODART)
     // cCodInv:=STRTRAN(cCodigo,CHR(183),"")
	
     IF ISSQLGET("DPINV","INV_CODIGO",UPPE(cCodInv))


        SQLUPDATE("DPINV","INV_FCHACT",DPINV->FECHA_MOD,"INV_CODIGO"+GetWhere("=",cCodInv))

        CREARSUSTITUTOS(cCodInv,MPRE_A)
        IF TYPE("MPRE_B")="N"
           CREARSUSTITUTOS(cCodInv,MPRE_B)
        ENDIF

        IF TYPE("MPRE_C")="N"
          CREARSUSTITUTOS(cCodInv,MPRE_C)
        ENDIF

        IF TYPE("MPRE_D")="N"
          CREARSUSTITUTOS(cCodInv,MPRE_D)
        ENDIF

        CREARSUSTITUTOS(cCodInv,NNOM_ART)
        CREARSUSTITUTOS(cCodInv,NNOM_ALT)

        oDp:cMemo:=oDp:cMemo+;
                   IIF( Empty(oDp:cMemo) , "" , CRLF )+;
                   "Código de Producto "+DPINV->CODART+" ya Existe"

        IF lMeter
          oMeterR:Set(nContar)
          oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodInv)
        ELSE
         oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodInv)
        ENDIF

        DPINV->(DBSKIP())

        LOOP

     ENDIF

     IF lMeter
       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodInv)
     ELSE
       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+cCodInv)
     ENDIF

     IF "TTA"$oTable:ClassName() 
       oTable:Append()
     ENDIF

     oTable:Replace("INV_IVA"   ,IIF(IVA="A","GN","EX"))
     oTable:Replace("INV_IVA"   ,IIF(IVA="B","RD",oTable:INV_IVA))

     oTable:Replace("INV_CODIGO",cCodInv)
     oTable:Replace("INV_DESCRI",DPINV->NOMART)
     oTable:Replace("INV_OBS1"  ,DPINV->NOMALT)
     oTable:Replace("INV_GRUPO" ,BUILDGRUPO(DPINV->GRUPO))
     oTable:Replace("INV_ESTADO","A") 
     oTable:Replace("INV_NUMMEM",BUILDMEMO(0,"",RESUMEN))   
     oTable:Replace("INV_CODMAR",BUILDMARCA(DPINV->MARCA))
     oTable:Replace("INV_EXIMIN",DPINV->EXMIN)
     oTable:Replace("INV_EXIMAX",DPINV->EXMAX)
     oTable:Replace("INV_COSMER",DPINV->ULT_COSTO)
     oTable:Replace("INV_COSUND",DPINV->COSTO_ACT)
     oTable:Replace("INV_FCHCRE",DPINV->FECHA_CREA)
     oTable:Replace("INV_FCHACT",   DPINV->FECHA_MOD)
     oTable:Replace("INV_UTILIZ","V")
     oTable:Replace("INV_APLICA","T")
     oTable:Replace("INV_PROCED","N")
     oTable:Replace("INV_METCOS","P")

     oTable:Commit(NIL,.F.)

     IF !ISSQLGET("DPINV","INV_CODIGO",cCodInv)
        // MensajeErr("Producto "+cCodInv+"no fué Creado")
        SysRefresh(.T.)
        DPINV->(DBSKIP())
        LOOP
     ENDIF

     // CREA_EQV(cCodInv,DPINV->MARCA)  
     // PREPARACION DE PRECIOS
     aPrecios:={"A","B","C","D"}

      FOR I=1 TO IIF(Empty(cCodigo),LEN(aPrecios),0)

          cPrecio:="PRECIO_"+aPrecios[I]
          uValue :=FieldGet(FieldPos(cPrecio))

          IF uValue>0 

             IF !ISSQLGET("DPPRECIOTIP","TPP_CODIGO",aPrecios[I])
                BUILDPRECIO(aPrecios[I])
             ENDIF

          ENDIF 

          // AQUI LAS UNIDADES DE MEDIDA
          UNDMED("UND",1         ,aPrecios[I],uValue,PESO,0)

          cPrecio:="PRECIO_"+aPrecios[I]
          uValue :=FieldGet(FieldPos(cPrecio))
          //UNDMED(INV_UNDGRU,INV_CXGRU ,aPrecios[I],uValue,INV_PESO,INV_VOLUME)

     NEXT I

// ? CODART,EXISTE_ACT,DPINV->COSTO_ACT,"CODART,EXISTE_ACT,DPINV->COSTO_ACT"

     EJECUTAR("DPINVEXIINI",CODART,EXISTE_ACT,DPINV->COSTO_ACT,"UND",1)

     CREARSUSTITUTOS(cCodInv,MPRE_A)
     CREARSUSTITUTOS(cCodInv,MPRE_B)
     CREARSUSTITUTOS(cCodInv,MPRE_C)
     CREARSUSTITUTOS(cCodInv,MPRE_D)
     CREARSUSTITUTOS(cCodInv,NNOM_ART)
     CREARSUSTITUTOS(cCodInv,NNOM_ALT)

     SysRefresh(.T.)
     DPINV->(DBSKIP())

   
     IF !Empty(cCodigo) // Para agregar Productos no Existentes
        EXIT
     ENDIF

  ENDDO

  oTable:End()

  IIF( lMeter , oMeterR:Set(RecCount()) ,  NIL )

  oTipPre:End()
  SELE DPINV
  USE
  DpSelect(cAlias)
 
RETURN NIL
/*
NOMBRE=DPSUSTITUTOS
 DESCRIPCION=Sustitutos                                                  
 CONFIG=F
 SINGUL=Sustituto                     
 APLICA=01
 PRIMARY_KEY=''
[END_ID]

[FIELDS]
 C001=SUS_CANTID          ,'N',010,3,'','Cantidad',0
 C002=SUS_CODIGO          ,'C',020,0,'','C¾digo',0
 C003=SUS_SUSTIT          ,'C',020,0,'','Sustituto',0
 C004=SUS_UNDMED          ,'C',008,0,'','Medida',0
[END_FIELDS]
*/

FUNCTION CREARSUSTITUTOS(cCodigo,cSustit)
  LOCAL cWhere:="SUS_CODIGO"+GetWhere("=",cCodigo)+" AND SUS_SUSTIT"+GetWhere("=",cSustit)

  IF Empty(cSustit)
     RETURN .T.
  ENDIF

  EJECUTAR("CREATERECORD","DPSUSTITUTOS",{"SUS_CODIGO","SUS_SUSTIT","SUS_UNDMED","SUS_CANTID" },; 
                                       {cCodigo     ,cSustit   ,oDp:cUndMed     ,1            } ,;
                                        NIL,.T.,cWhere)

  SysRefresh(.t.)

RETURN .T.

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

    cUnd:=BUILDUNDMED(UPPE(cUnd))
/*
    IF !Empty(cUnd) .AND. COUNT("DPUNDMED","UND_CODIGO"+GetWhere("=",cUnd))=0
       oTable:=OpenTable("SELECT * FROM DPUNDMED",.F.)
       oTable:AppendBlank()
       oTable:Replace("UND_CODIGO",cUnd )
       oTable:Replace("UND_DESCRI",cUnd )
       oTable:Replace("UND_CANUND",nCant)
       oTable:Commit()
       oTable:End()
    ENDIF
*/

    cWhere:="PRE_LISTA" +GetWhere("=",cPrecio   )+;
            " AND PRE_CODIGO"+GetWhere("=",CODART    )+;
            " AND PRE_UNDMED"+GetWhere("=",cUnd      )+;
            " AND PRE_CODMON"+GetWhere("=",oDp:cMonedaExt)


    IF nPrecio>0 .AND. COUNT("DPPRECIOS",cWhere)=0
/*
PRE_LISTA" +GetWhere("=",cPrecio   )+;
                    " AND PRE_CODIGO"+GetWhere("=",CODART    )+;
                    " AND PRE_UNDMED"+GetWhere("=",cUnd      )+;
                    " AND PRE_CODMON"+GetWhere("=",oDp:cMonedaExt))=0
*/
       oTable:=OpenTable("DPPRECIOS",.F.)
       oTable:Append()
       oTable:Replace("PRE_LISTA" ,cPrecio)
       oTable:Replace("PRE_UTILID",FIELDGET(FIELDPOS("INV_UTIL"+cPrecio)))
       oTable:Replace("PRE_CODIGO",CODART)
       oTable:Replace("PRE_PRECIO",nPrecio)
       oTable:Replace("PRE_UNDMED",cUnd)
       oTable:Replace("PRE_CODMON",oDp:cMonedaExt)
       oTable:Commit(NIL,.F.)
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
    oTable:Commit(NIL,.F.)
    oTable:End()

RETURN .T.

/*
// Obtiene el Grupo
*/
FUNCTION BUILDGRUPO(cGrupo)
  LOCAL oTable

  IF Empty(cGrupo)
     cGrupo:="SINCOD"
     //SQLINCREMENTAL("DPGRU","GRU_CODIGO")
  ENDIF

  IF SQLGET("DPGRU","GRU_CODIGO","GRU_CODIGO"+GetWhere("=",cGrupo))=cGrupo
     RETURN cGrupo
  ENDIF
  
  oTable:=OpenTable("SELECT * FROM DPGRU",.F.)
  oTable:Append()
  oTable:Replace("GRU_CODIGO",cGrupo)
  oTable:Replace("GRU_DESCRI",cGrupo)
  oTable:Commit(NIL,.F.)
  oTable:End()

RETURN cGrupo

FUNCTION HACERPRECIOS(cFile)
   LOCAL aPrecios:={"A","B","C","D"},I,U
// LOCAL oTable :=OpenTable("DPPRECIOTIP",.F.)
   LOCAL oUndMed:=OpenTable("DPUNDMED"   ,.F.)
   LOCAL oPrecio:=OpenTable("DPPRECIOS"  ,.F.)
   LOCAL nPrecio,cPrecio,aTipos:={"U","G","O"}
   LOCAL aUndMed:={"UND","GRU","OTR"}

   CLOSE ALL

   FOR I=1 TO LEN(aPrecios)
      BUILDPRECIO(aPrecios[I])
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
             oPrecio:Commit(NIL,.F.)
          ENDIF

        NEXT U
     NEXT I

     SKIP

   ENDDO
   USE

   oUndMed:End()

RETURN .T.

// en Mix no Existe DPMEMO
FUNCTION BUILDMEMO(nNumMem,cDescri,cMemo)
  LOCAL cAlias:=ALIAS(),cFile,cIndex,oMemo

  DEFAULT cDescri:=""

  IF Empty(cMemo)
     RETURN 0
  ENDIF

  nNumMem:=SQLINCREMENTAL("DPMEMO","MEM_NUMERO")
  oMemo:=OpenTable("DPMEMO",.F.)
  oMemo:REPLACE("MEM_NUMERO",nNumMem)
  oMemo:REPLACE("MEM_MEMO"  ,OEMTOANSI(cMemo))
  oMemo:REPLACE("MEM_DESCRI",IIF(EMPTY(oMemo:MEM_DESCRI),OEMTOANSI(cDescri),oMemo:MEM_DESCRI))
  oMemo:Commit(NIL,.F.)
  oMemo:End()

  DPSELECT(cAlias)

RETURN nNumMem

/*
Unidad de Medida
*/
FUNCTION BUILDUNDMED(cUnd)

   LOCAL oTable

   cUnd:=UPPE(cUnd)

   IF !Empty(cUnd) .AND. !ISSQLGET("DPUNDMED","UND_CODIGO",cUnd)
      oTable:=OpenTable("SELECT * FROM DPUNDMED",.F.)
      oTable:AppendBlank()
      oTable:Replace("UND_CODIGO",cUnd )
      oTable:Replace("UND_DESCRI",cUnd )
      oTable:Replace("UND_CANUND",nCant)
      oTable:Commit()
      oTable:End()
   ENDIF

RETURN cUnd


//
// Importar Vendedores
//
FUNCTION DPALM()
   LOCAL cFile:=cDir+"DPALM.DBF",cCodAlm,nContar:=0

   LOCAL oTable

   CLOSE ALL

   oTable:=OpenTable("DPALMACEN",.F.)

   SELE A
   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
   DBGOTOP()

   IF lMeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("Almacén")
   ENDIF

   WHILE !A->(EOF())

     cCodAlm:=A->ALM_CODIGO
     nContar++
     IF lMeter

      oMeterR:Set(nContar)
      oSayR:SetText(LSTR(nContar)+"/"+LSTR(A->(RECCOUNT()))+" "+ALM_CODIGO)

     ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+ALM_CODIGO)

     ENDIF

     IF ALLDIGIT(cCodAlm)
        cCodAlm:=STRZERO(VAL(cCodAlm),LEN(oTable:ALM_CODIGO))
     ENDIF

     IF !ISSQLGET("DPALMACEN","ALM_CODIGO",cCodAlm)

        oTable:AppendBlank()

        AEVAL(DBSTRUCT(),{|a,n,uValue|uValue:=FieldGet(n),;
                                      uValue:=IIF(ValType(uValue)="C",OEMTOANSI(uValue),uValue),;
                                      IIF(oTable:IsDef(FIELDNAME(n),;
                                      oTable:Replace(FIELDNAME(n),uValue)),NIL)})

        oTable:Replace("ALM_CODIGO",cCodAlm)
        oTable:Replace("ALM_CODSUC",oDp:cSucursal)
        oTable:Replace("ALM_DESCRI",ANSITOOEM(A->ALM_DESCRI))
        oTable:Commit()

     ENDIF

     A->(DBSKIP())

   ENDDO

   USE
   oTable:End()

RETURN .T.


//
// Importar Vendedores
//
FUNCTION DPGRU()
   LOCAL cFile:=cDir+"MXGRUINV.DBF",cCodGRU,nContar:=0
   LOCAL oTable

   IF !FILE(cFile)
      RETURN .T.
   ENDIF

   CLOSE ALL

   oTable:=OpenTable("DPGRU",.F.)

   SELE A
   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
// BROWSE()
   DBGOTOP()

   IF lMeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("GRUPOS")
   ENDIF

   WHILE !A->(EOF())

     cCodGru:=A->GRUART
     nContar++

     IF lMeter

      oMeterR:Set(nContar)
      oSayR:SetText(LSTR(nContar)+"/"+LSTR(A->(RECCOUNT()))+" "+GRU_CODIGO)

     ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+GRU_CODIGO)

     ENDIF

     IF !ISSQLGET("DPGRU","GRU_CODIGO",cCodGRU)

        oTable:AppendBlank()
        oTable:Replace("GRU_CODIGO",cCodGRU)
        oTable:Replace("GRU_DESCRI",ANSITOOEM(A->NOMGRUART))
        oTable:Commit(NIL,.F.)

     ELSE

        SQLUPDATE("DPGRU","GRU_DESCRI",ANSITOOEM(A->NOMGRUART),"GRU_CODIGO"+GetWhere("=",cCodGru))

     ENDIF

     A->(DBSKIP())

   ENDDO

   USE
   oTable:End()

RETURN .T.


// IMPORTAR MARCAS DESDE MIXNET
FUNCTION DPMARCAS()
   LOCAL cFile:=cDir+"MXMARINV.DBF",cCodMAR,nContar:=0

   LOCAL oTable

   IF !FILE(cFile)
      RETURN .T.
   ENDIF

   CLOSE ALL

   oTable:=OpenTable("DPMARCAS",.F.)

   SELE A
   USE (ALLTRIM(cFile)) VIA "DBFCDX" SHARED NEW 
   DBGOTOP()

   IF lMeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("MARCAS")
   ENDIF

   WHILE !A->(EOF())

     cCodMAR:=A->MARART
     nContar++

     IF lMeter

      oMeterR:Set(nContar)
      oSayR:SetText(LSTR(nContar)+"/"+LSTR(A->(RECCOUNT()))+" "+MARART)

     ELSE

      oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT())+" "+MARART)

     ENDIF



     IF !ISSQLGET("DPMARCAS","MAR_CODIGO",cCodMAR)

        oTable:AppendBlank()

        oTable:Replace("MAR_CODIGO",cCodMAR)
        oTable:Replace("MAR_DESCRI",ANSITOOEM(A->NOMMARART))
        oTable:Replace("MAR_DIRWEB","")
        oTable:Replace("MAR_MEMO","")
        oTable:Replace("MAR_FILBMP","")

        oTable:Commit(NIL,.F.)

     ENDIF

     A->(DBSKIP())

   ENDDO

   USE
   oTable:End()

RETURN .T.

FUNCTION CREA_EQV(cCodigo,cCodAlt)
   IF Empty(cCodigo) .OR. Empty(cCodAlt)
      RETURN .T.
   ENDIF

   oTable:=OpenTable("SELECT * FROM DPEQUIV WHERE EQUI_CODIG"+GetWhere("=",cCodigo)+" AND "+;
                     " EQUI_BARRA"+GetWhere("=",cCodAlt),.T.)
   IF oTable:RecCount()=0
      oTable:Append()
      oTable:Replace("EQUI_CODIG",cCodigo)
      oTable:Replace("EQUI_BARRA",cCodAlt)
      oTable:Replace("EQUI_MED"  ,"UND")
      oTable:Commit()
   ENDIF
   oTable:End()

RETURN .T.
/*
// Busca la Marca
*/
FUNCTION BUILDMARCA(cCodMar)
RETURN cCodMar
/*
// Ya fué Verificado el Tipo
*/
// EOF



