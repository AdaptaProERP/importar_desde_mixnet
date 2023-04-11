// Programa   : IMPORTMOVMIX        
// Fecha/Hora : 01/01/2018 02:34:15
// Propósito  : Importar Movimiento de Productos
// Creado Por : Juan Navas
// Llamado por: DPIMPRXLSRUN   
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,oMeterT,oMeterR,oSayT,oSayR,nTables,lInicia)
   LOCAL lMeter:=(ValType(oMeterR)="O")
   LOCAL cFileDbf,lBrowse:=!lMeter
   LOCAL oMov,aFields:={},aVars:={},aSelect:={}
   LOCAL cTipo,cTipDoc,nContar:=0

   DEFAULT cDir     :="C:\MIXNET\COMP01\",;
           lInicia  :=.T.,;
           oDp:cMemo:=""

   rddSetDefault( "DBF" )

   oDp:lTracer:=.F.

   IF lInicia
     SQLDELETE("DPMOVINV","MOV_USUARI"+GetWhere("=","MIX"))
   ENDIF

   cFileDbf:=cDir+"MXTRAINV.DBF" 

   IF !FILE(cFileDbf)
      MensajeErr("Archivo "+cFileDbf+" no Existe")
      RETURN .F.
   ENDIF
 
   SELE A
   USE (cFileDbf) SHARED

   IF RECCOUNT()=0
      MensajeErr(cFileDbf+" sin Registros")
      CLOSE ALL
      RETURN .F.
   ENDIF
  
   IF lBrowse 
     BROWSE()
     // CLOSE ALL
     // RETURN NIL
   ENDIF

   IF !oMeterR=NIL
     oMeterR:SetTotal(RECCO())
   ENDUF

   AEVAL(aSelect,{|a,n|aSelect[n,3]:=ALLTRIM(a[3])})

   // BROWSE()

   // oMov:=OpenTable("SELECT * FROM DPMOVINV",.F.)
   oMov:=INSERTINTO("DPMOVINV",.F.)
   oMov:nInsert:=200

   // oMov:SetForeignkeyOff()

   IF lmeter
     oMeterR:SetTotal(RecCount())
     oSayT:SetText("MOV")
   ENDIF

   WHILE !A->(EOF()) 

       IF Empty(A->CODMOVART)
           A->(DbSkip())
           LOOP
       ENDIF

       nContar++
       cTipDoc:=A->ORIGEN
       cTipDoc:=IF(cTipDoc="ALB","NEN",cTipDoc)

       CursorWait()

       IF nContar%50=0 
  
          SysRefresh(.T.)

          IF lmeter
           oMeterR:Set(nContar)
           oSayR:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
          ELSE
           oDp:oFrameDp:SetText(LSTR(nContar)+"/"+LSTR(RECCOUNT()))
          ENDIF

       ENDIF

       cTipo:=A->TIPINV
       cTipo:=IF(cTipo="EN","E001","S001")
 
       IF A->TIPINV="DV"
         cTipo:="E001"
       ENDIF

       oMov:AppendBlank()
       oMov:Replace("MOV_CODIGO" ,A->CODMOVART) //C(15)
       oMov:Replace("MOV_FECHA"  ,A->FECHA_MOV) //D(8)
       oMov:Replace("MOV_HORA"   ,A->HORA)   //C(6)
       oMov:Replace("MOV_CODTRA" ,cTipo)   //C(2)
       oMov:Replace("MOV_TIPDOC" ,A->ORIGEN) //C(2) 

       oMov:Replace("MOV_DOCUME" ,A->NUMDOC) //C(10)
       oMov:Replace("MOV_UNDMED" ,"UND") // A->UNIDAD) //C(3)
       oMov:Replace("MOV_CANTID" ,A->CANTIDAD) //N(14)
       oMov:Replace("MOV_COSTO"  ,A->COSTO_TOT) //N(19)
       oMov:Replace("MOV_ORIGEN" ,A->ORIGEN) //C(3) 
       oMov:Replace("MOV_CODCTA" ,A->PROV_CLI) //C(10)
       oMov:Replace("MOV_TOTAL"  ,A->VENTA_TOT) //N(17)
       oMov:Replace("MOV_APLORG" ,A->ORIGEN)
       oMov:Replace("MOV_CXUND",1)

       oMov:Replace("MOV_CODALM",oDp:cCodAlm)
       oMov:Replace("MOV_CODSUC",oDp:cSucursal)
       oMov:Replace("MOV_INVACT",1)
       oMov:Replace("MOV_FISICO",IF(LEFT(cTipo,1)="E" ,1,-1))
       oMov:Replace("MOV_LOGICO",IF(LEFT(cTipo,1)="E" ,1,-1))
       oMov:Replace("MOV_CONTAB",IF(LEFT(cTipo,1)="E" ,1,-1))
       oMov:Replace("MOV_METCOS","P")
       oMov:Replace("MOV_ASOTIP",A->TIPINV)
       oMov:Replace("MOV_USUARI","MIX"  )  
       oMov:Commit()
      
       // Si esta en Revision, No agrega producto

       A->(DbSkip())

       IF RECNO()%5=0
         SysRefresh(.T.)
       ENDIF

   ENDDO

   oMov:End()

   IF(lMeter , oMeterT:Set(nTables++) , NIL)
 
   CLOSE ALL
  
RETURN lOk

// EOF

