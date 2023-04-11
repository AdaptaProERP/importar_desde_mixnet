// Programa   : IMPORTBCOMIX
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
     SQLDELETE("DPBANCOS")
     SQLDELETE("DPCTABANCO_CTA")
     SQLDELETE("DPCTABANCO")
     SQLDELETE("DPCTABANCOMOV")
   ENDIF


   DPBANCOS(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)
   DPCTABANCOMOV(cDir)
   IF(lMeter , oMeterT:Set(nTables++) , NIL)

   oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")

RETURN nTables


PROCE DPCTABANCOMOV(cDir)
  LOCAL cFile:=cDir+"MXTRABAN.DBF",nContar:=0,oTable,cCodBco,cCtaBco

  IF COUNT("DPCTABANCOMOV")>0
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

  oTable :=OpenTable("DPCTABANCOMOV",.F.)
  oTable:SetInsert(200)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Movimientos Bancarios")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     cCodBco:=ALLTRIM(A->CODMOVBAN)

     IF EMPTY(cCodBco) .OR. LEN(cCodBco)<>2
        A->(DBSKIP())
        LOOP
     ENDIF

     cCodBco:=REPLI("0",6-LEN(cCodBco))+cCodBco
     cCtaBco:=SQLGET("DPCTABANCO","BCO_CTABAN","BCO_CODIGO"+GetWhere("=",cCodBco))

     nContar++

     IF recno()%10=0

       IF lmeter
         oMeterR:Set(nContar)
         oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ELSE
         oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ENDIF

     ENDIF

     oTable:ReplaceSpeed("MOB_CODBCO" ,cCodBco      )
     oTable:ReplaceSpeed("MOB_DOCUME" ,A->NUMDOC    )
     oTable:ReplaceSpeed("MOB_FECHA"  ,A->FECHA_MOV )
     oTable:ReplaceSpeed("MOB_DESCRI" ,A->CONCEPTO  )
     oTable:ReplaceSpeed("MOB_USUARI" ,"MIX"        )
     oTable:ReplaceSpeed("MOB_CUENTA" ,cCtaBco      )
     oTable:ReplaceSpeed("MOB_ACT"    ,1            )
     oTable:ReplaceSpeed("MOB_MONTO"  ,A->IMPORTE   )
     oTable:ReplaceSpeed("MOB_CODSUC" ,oDp:cSucursal)
     oTable:ReplaceSpeed("MOB_TIPO"   ,A->TIPBAN   )
     oTable:ReplaceSpeed("MOB_CTACON" ,A->CODCONBAN)
     oTable:ReplaceSpeed("MOB_ORIGEN" ,A->ORIGEN   )
     oTable:ReplaceSpeed("MOB_DOCASO" ,A->NUMORG   )
     oTable:ReplaceSpeed("MOB_COMPRO" ,A->ASIENTO  )
     oTable:CommitSpeed(.F.)

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

  SQLUPDATE("DPCTABANCOMOV","MOB_TIPO","DEP","MOB_TIPO"+GetWhere("=","DP"))
  SQLUPDATE("DPCTABANCOMOV","MOB_TIPO","CHQ","MOB_TIPO"+GetWhere("=","CH"))
  SQLUPDATE("DPCTABANCOMOV","MOB_TIPO","DEB","MOB_TIPO"+GetWhere("=","ND"))
  SQLUPDATE("DPCTABANCOMOV","MOB_TIPO","CRE","MOB_TIPO"+GetWhere("=","NC"))

RETURN .T.

PROCE DPBANCOS(cDir)
  LOCAL cFile:=cDir+"MXCTABAN.DBF",nContar:=0,oTable,oTableC
  LOCAL cCodBco

  IF COUNT("DPBANCOS")>0
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

  oTable :=OpenTable("DPBANCOS",.F.)
  oTable:SetInsert(200)

  oTableC:=OpenTable("DPCTABANCO",.F.)
  oTableC:SetInsert(200)

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("Cuentas")
  ENDIF

  SELE A
  WHILE !A->(EOF())

     cCodBco:=ALLTRIM(A->CODBAN)

     IF EMPTY(cCodBco) .OR. LEN(cCodBco)<>2
        A->(DBSKIP())
        LOOP
     ENDIF

     cCodBco:=REPLI("0",6-LEN(cCodBco))+cCodBco
     nContar++
     IF lmeter
       oMeterR:Set(nContar)
       oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ELSE
       oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
     ENDIF

     oTable:ReplaceSpeed("BAN_CODIGO",cCodBco    )
     oTable:ReplaceSpeed("BAN_NOMBRE",A->NOMBRE  )
     oTable:ReplaceSpeed("BAN_ACTIVO",.T.        )
     oTable:CommitSpeed(.F.)

     //  LA CUENTA BANCARIA

     oTableC:ReplaceSpeed("BCO_CODIGO",cCodBco    )
     oTableC:ReplaceSpeed("BCO_CTABAN",A->CUENTA    )
     oTableC:ReplaceSpeed("BCO_ACTIVA",.T.        )
     oTableC:ReplaceSpeed("BCO_CODMON",oDp:cMoneda  )
     oTableC:ReplaceSpeed("BCO_TIPCTA","Corriente"  )
     oTableC:CommitSpeed(.F.)

     IF !Empty(A->CODCON)
       EJECUTAR("SETCTAINTMOD","DPCTABANCO_CTA",cCodBco,A->CUENTA,"CUENTA",A->CODCON,.T.)
     ENDIF

     DBSKIP()

  ENDDO

  oTable:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL

   
RETURN NIL
// eof

