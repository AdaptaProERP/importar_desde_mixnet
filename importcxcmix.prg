// Programa   : IMPORTCXCMIX
// Fecha/Hora : 04/03/2006 10:18:45
// Prop¢sito  : Importar Cuentas por Cobrar desde MIXNET
// Creado Por : Miguel Figueroa
// Llamado por: IMPORTDP
// Aplicaci¢n : Def
// Tabla      : 
/*
La tabla MXTRACOB.DBF solo están los movimientos por tipo= “ND” o “NC” o “FC” o “AB” o “CA” y cada tipo tiene un importe si son 
FC=factura el importe es positivo al igual que las ND=notas de débito y los AB= abonos y CA= cancelaciones NC=notas de crédito 
son negativos no hay en esa tabla totales o saldo del cliente ese campo se encuentra en la tabla de MXCTACLI.DBF 
que es la que contiene los datos del cliente
*/
#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lInicia)

   LOCAL lMeter:=(ValType(oMeterR)="O")

   DEFAULT cDir     :="C:\MIXNET\COMP01\",;
           lInicia  :=.T.,;
           oDp:cMemo:=""

   rddSetDefault( "DBF" )

   oDp:lTracer:=.F.

   IF lInicia
      SQLDELETE("DPDOCCLI")
   ENDIF

   DPCXC(cDir)

   IF(lMeter , oMeterT:Set(nTables++) , NIL)

   CLOSE ALL

RETURN nTables

PROCE DPCXC(cDir)
  LOCAL cFile:=cDir+"MXTRACOB",cCodCli:="",nContar:=0,oTable
  LOCAL cTipDoc,nCxC,cCodMon,cTipTra
  LOCAL oDb:=OpenOdbc(oDp:cDsnData)
  LOCAL oCliente,oTipDoc

  CLOSE ALL
  SELE A
  USE (cFile) VIA "DBFCDX" SHARED NEW 

  //BROWSE()

  DBGOTOP()

  oCliente:=OpenTable("SELECT * FROM DPCLIENTES",.F.)
  oCliente:SetForeignkeyOff()

  oTipDoc:=OpenTable("SELECT * FROM DPTIPDOCCLI",.F.)

  oTable:=INSERTINTO("DPDOCCLI",.F.)
  oTable:nInsert:=200
  // oDb:Execute("SET FOREIGN_KEY_CHECKS = 0")

  IF lmeter
    oMeterR:SetTotal(RecCount())
    oSayT:SetText("CxC")
  ENDIF

  SELE A
  GO TOP

  oDp:lSaveSqlFile:=.F.

  WHILE !A->(EOF())

     nContar++

     IF nContar%10=0 

       SysRefresh(.T.)

       IF lmeter
         oMeterR:Set(nContar)
         oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ELSE
         oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
       ENDIF

     ENDIF

     cTipDoc:=A->ORIGEN
     cTipDoc:=IF(cTipDoc="ALB","NEN",cTipDoc)
     cTipDoc:=IF(cTipDoc="FAC","FAV",cTipDoc)

     cCodMon:=A->MONEDA
     cCodMon:=IF(cCodMon="US$","DBC",cCodMon)

     nCxC   :=IF(A->IMPORTE>0,1,-1)

     cTipTra:=IF(nCxC=1,"D","P")

     IF !ISSQLFIND("DPCLIENTES","CLI_CODIGO"+GetWhere("=",LEFT(A->CODMOVCLI,10)))
        oCliente:AppendBlank()
        oCliente:Replace("CLI_CODIGO",LEFT(A->CODMOVCLI,10))
        oCliente:Replace("CLI_NOMBRE",LEFT(A->CODMOVCLI,10))
        oCliente:Commit("")
     ENDIF

     IF !ISSQLFIND("DPTIPDOCCLI","TDC_TIPO"+GetWhere("=",cTipDoc))
        oTipDoc:AppendBlank()
        oTipDoc:Replace("TDC_TIPO"  ,cTipDoc)
        oTipDoc:Replace("TDC_DESCRI",cTipDoc)
        oTipDoc:Commit("")
     ENDIF

     oTable:AppendBlank()
     oTable:Replace("DOC_CODIGO",LEFT(A->CODMOVCLI,10))
     oTable:Replace("DOC_NUMERO",LEFT(A->NUMDOC   ,10))
     oTable:Replace("DOC_VALCAM",A->CAMBIO    )
     oTable:Replace("DOC_CODSUC",oDp:cSucursal)
     oTable:Replace("DOC_FECHA" ,A->EMISION   )
     oTable:Replace("DOC_FCHVEN",A->VENCE     )
     oTable:Replace("DOC_NETO"  ,ABS(A->IMPORTE))
     oTable:Replace("DOC_CXC"   ,nCxC         )
     oTable:Replace("DOC_ACT"   ,1            )
     oTable:Replace("DOC_MTOIVA",A->IMP_IVA   )
     oTable:Replace("DOC_TIPTRA",cTipTra      )
     oTable:Replace("DOC_TIPDOC",cTipDoc      )
     oTable:Replace("DOC_CODMON",cCodMon      )
     oTable:Replace("DOC_DOCORG","D"          )

     oTable:Commit()

     DBSKIP()

  ENDDO

  // oDb:Execute("SET FOREIGN_KEY_CHECKS = 1")

  oTable:End()
  oCliente:End()
  
  IIF(lMeter,oMeterR:Set(RecCount()),NIL)

  CLOSE ALL
   
RETURN NIL

// EOF
