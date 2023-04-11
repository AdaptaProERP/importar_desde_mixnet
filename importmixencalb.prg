// Programa   : IMPORTMIXENCALB
// Fecha/Hora : 20/07/2022 22:26:37
// Propósito  : Genera Albaranes como Tipo de Documento pendiente por Cobrar
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cDir,cTipDoc,cDescri)
  LOCAL oTable,cFileDoc,cFileCli,cWhere,cCodInv,cWhere,cCodSuc:=oDp:cSucursal,nContar:=0,nValCam:=1
  LOCAL cNumero:="",oMovInv,nMonto:=0,nPrecio
  LOCAL nT1:=SECONDS()

  DEFAULT cDir   :="C:\MIXCLUB\COMP01\",;
          cTipDoc:="CUO",;
          cDescri:="Cuotas Mensuales"

  EJECUTAR("DPCREATERCEROS")
  EJECUTAR("DPTIPDOCCLICREA",cTipDoc,cDescri,"D")

  cFileDoc:=cDir+"MXENCALB.DBF"

  SQLDELETE("DPDOCCLI","DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_TIPORG"+GetWhere("=","MIX"))
  SQLDELETE("DPMOVINV","MOV_ASOTIP"+GetWhere("=","MIX"))


  oMovInv:=OpenTable("SELECT * FROM DPMOVINV",.F.)

  oTable:=OpenTable("SELECT * FROM DPDOCCLI",.F.)
  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")

  CLOSE ALL
  SELECT B
  USE (cFileDoc)

  SET FILTER TO ESTATUS = "PE"
  GO TOP

  WHILE !B->(EOF()) 

     
     IF B->ESTATUS = "PE" 

       nContar++
       cNumero:=LEFT(B->NUMALB,2)+"00"+RIGHT(B->NUMALB,6)

       nMonto :=B->TOT_ALB
       nValCam:=5

       IF LEFT(cNumero,2)="GA"
          nMonto:=ROUND(30*nValCam,2)
       ELSE
          nMonto:=ROUND(41*nValCam,2)
       ENDIF

       EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,B->CLIENTE,B->EMISION,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,VENCE)

       //EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,B->NUMFAC,B->CLIENTE,B->EMISION,oDp:cMonedaExt,"V",NIL,TOT_FAC,IMP_IVA,CAMBIO,VENCE)

       SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))

       EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,nMonto,"MENSUAL",1,0,"",VENCE,"V",VENCE,B->CLIENTE,"GN",0,nValCam,oMovInv)

       nPrecio:=nMonto/(1.16)
       SQLUPDATE("DPMOVINV",{"MOV_ASOTIP","MOV_FECHA","MOV_IVA","MOV_PRECIO","MOV_TOTAL","MOV_LISTA"},{"MIX",B->EMISION,16,nPrecio,nPrecio,"A"},"MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND MOV_DOCUME"+GetWhere("=",cNumero))

     ENDIF

     SELECT B
   
     SKIP 

     IF nContar>5
     //   EXIT
     ENDIF

  ENDDO

  SQLUPDATE("DPCLIENTES","CLI_CODMON","DBC")

  ? LSTR(nContar)+" Registros Migrados en "+LSTR(ABS(SECONDS()-nT1)/60)+" Minutos"

  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")
  oTable:End()

  SELECT B

  CLOSE ALL

  oMovInv:End()
 
RETURN .T.
// EOF
