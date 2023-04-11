// Programa   : IMPORTCONMIX
// Fecha/Hora : 04/03/2006 10:18:45
// Prop¢sito  : Importar Inventarios desde DP20
// Creado Por : Juan Navas
// Llamado por: IMPORTMIX
// Aplicaci¢n : Def
// Tabla      : 

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lInicia)
   LOCAL cCta
   LOCAL lMeter:=(ValType(oMeterR)="O")
   LOCAL oDb   :=OpenOdbc(oDp:cDsnData)

   DEFAULT cDir     :="C:\distrilab\COMP01\",;
           lInicia  :=.T.,;
           oDp:cMemo:=""

   rddSetDefault( "DBF" )

  oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")


   IF lInicia
      SQLDELETE("DPCTA")
      SQLDELETE("DPCBTE")
      SQLDELETE("DPASIENTOS")
   ENDIF


   DPCTA(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)
   DPCBTE(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)
   DPASIENTOS(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)

/*
   CLOSE ALL
   SELECT A
   cCta:=cDir+"MXRENCON.DBF"

   // cCta:=cDir+"MXENCCON.DBF"


   USE (cCta) 

? FILE(cCta),cCta,RECCOUNT()

   BROWSE()

   CLOSE ALL
*/

   EJECUTAR("DPCBTEFIX")

   oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")

RETURN nTables

PROCE DPCBTE(cDir)
  LOCAL cFile:=cDir+"MXENCCON.DBF",nContar:=0,oTable

  IF COUNT("DPCBTE")>0
     RETURN .F.
  ENDIF

  IF !FILE(cFile)
     MsgMemo(cFile+" no Existe")
     RETURN .F.
  ENDIF

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 

  DBGOTOP()

  oTable :=OpenTable("DPCBTE",.F.)
  oTable:SetInsert(200)


  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Comprobantes")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     nContar++
     IF lmeter
       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ELSE
       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ENDIF

     oTable:ReplaceSpeed("CBT_NUMERO",A->ASIENTO  )
     oTable:ReplaceSpeed("CBT_FECHA" ,A->FECHA_ASI)
     oTable:ReplaceSpeed("CBT_COMEN1",LEFT(A->DESC_ASI,60) )
     oTable:ReplaceSpeed("CBT_COMEN2",SUBS(A->DESC_ASI,61,250) )
     oTable:ReplaceSpeed("CBT_ACTUAL","S")
     oTable:ReplaceSpeed("CBT_CODSUC",oDp:cSucursal)
     oTable:ReplaceSpeed("CBT_NUMEJE",oDp:cNumEje)
     oTable:ReplaceSpeed("CBT_ORIGEN","MIX")
     oTable:CommitSpeed(.F.)

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

RETURN .T.


PROCE DPASIENTOS(cDir)
  LOCAL cFile:=cDir+"MXRENCON.DBF",nContar:=0,oTable

  IF COUNT("DPASIENTOS")>0
     RETURN .F.
  ENDIF

  IF !FILE(cFile)
     MsgMemo(cFile+" no Existe")
     RETURN .F.
  ENDIF

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 

  DBGOTOP()

  oTable :=OpenTable("DPASIENTOS",.F.)
  oTable:SetInsert(200)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Asientos")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     nContar++

     IF recno()%10=0

       IF lmeter
         oMeterR:Set(nContar)
         oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ELSE
         oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ENDIF

     ENDIF

     oTable:ReplaceSpeed("MOC_CUENTA",A->CODMOV   )
     oTable:ReplaceSpeed("MOC_DOCUME",A->REFER    )
     oTable:ReplaceSpeed("MOC_FECHA" ,A->FECHA_ASI)
     oTable:ReplaceSpeed("MOC_DESCRI",A->CONCEPTO )
     oTable:ReplaceSpeed("MOC_ACTUAL","S"         )
     oTable:ReplaceSpeed("MOC_CTAMOD",oDp:cCtaMod  )
     oTable:ReplaceSpeed("MOC_CODSUC",oDp:cSucursal)
     oTable:ReplaceSpeed("MOC_CODDEP",A->CODDPTO   )
     oTable:ReplaceSpeed("MOC_MONTO" ,A->IMPORTE   )
     oTable:ReplaceSpeed("MOC_NUMCBT",A->ASIENTO   )
     oTable:ReplaceSpeed("MOC_NUMEJE",oDp:cNumEje)
     oTable:ReplaceSpeed("MOC_ORIGEN","MIX")
     oTable:CommitSpeed(.F.)

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

  SQLUPDATE("DPASIENTOS","MOC_CODDEP",STRZERO(2,10),"MOC_CODDEP"+GetWhere("=","002"))
  SQLUPDATE("DPASIENTOS","MOC_CODDEP",STRZERO(3,10),"MOC_CODDEP"+GetWhere("=","003"))
  SQLUPDATE("DPASIENTOS","MOC_CODDEP",STRZERO(4,10),"MOC_CODDEP"+GetWhere("=","004"))
  SQLUPDATE("DPASIENTOS","MOC_CODDEP",STRZERO(5,10),"MOC_CODDEP"+GetWhere("=","005"))
  SQLUPDATE("DPASIENTOS","MOC_CODDEP",STRZERO(0,10),"MOC_CODDEP"+GetWhere("=","A"))
  SQLUPDATE("DPASIENTOS","MOC_CODDEP","Indefinido" ,"MOC_CODDEP"+GetWhere("=",""))

RETURN .T.

PROCE DPCTA(cDir)
  LOCAL cFile:=cDir+"MXCTACON.DBF",nContar:=0,oTable

  IF COUNT("DPCTA")>0
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

  oTable :=OpenTable("DPCTA",.F.)
  oTable:SetInsert(200)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Cuentas")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     IF EMPTY(A->CODIGO)
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

     oTable:ReplaceSpeed("CTA_CODIGO",A->CODIGO  )
     oTable:ReplaceSpeed("CTA_DESCRI",A->NOMBRE  )
     oTable:ReplaceSpeed("CTA_ACTIVO",.T.        )
     oTable:ReplaceSpeed("CTA_CODMOD",oDp:cCtaMod)
     oTable:CommitSpeed(.F.)

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

  EJECUTAR("SETDPCTADET")
   
RETURN NIL
// eof
