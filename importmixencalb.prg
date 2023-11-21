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
  LOCAL cNumero:="",oMovInv,nMonto:=0,nPrecio,nCxC,cSql
  LOCAL nT1:=SECONDS(),dFchIniMes


  DEFAULT cDir   :="C:\MIXCLUB\COMP01\",;
          cTipDoc:="CUO",;
          cDescri:="Cuotas Mensuales"

  EJECUTAR("DPCREATERCEROS")
  EJECUTAR("DPTIPDOCCLICREA",cTipDoc,cDescri,"D")

  cFileDoc:=cDir+"MXENCALB.DBF"

  SQLDELETE("DPDOCCLI","DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_TIPORG"+GetWhere("=","MIX"))
  SQLDELETE("DPMOVINV","MOV_ASOTIP"+GetWhere("=","MIX"))

  nCxC   :=EJECUTAR("DPTIPCXC",cTipDoc)

  oMovInv:=INSERTINTO("DPMOVINV",NIL,10)

  oMovInv:lAuditar:=.F.
  oMovInv:lFileLog:=.F.

  oTable:=INSERTINTO("DPDOCCLI",NIL,10)

  oTable:lAuditar:=.F.
  oTable:lFileLog:=.T.
 
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
       // 16/11/2023, los datos migran como estan
       nMonto :=B->TOT_ALB
       nValCam:=B->CAMBIO

/*
       // Código Anterior al 14/11/2023
       nValCam:=5
       IF LEFT(cNumero,2)="GA"
          nMonto:=ROUND(30*nValCam,2)
       ELSE
          nMonto:=ROUND(41*nValCam,2)
       ENDIF

       // cuotas hasta 30/06/2022 siguen en 10 usd
       IF B->EMISION<CTOD("01/07/2023")
          nMonto:=ROUND(10*nValCam,2)
       ENDIF
*/

       EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,B->CLIENTE,B->EMISION,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC)

       SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))

       EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,nMonto,"MENSUAL",1,0,"",VENCE,"V",VENCE,B->CLIENTE,"GN",0,nValCam,oMovInv)

//  14/11/2023 Resuelve mediante query
//     nPrecio:=nMonto/(1.16)
//     SQLUPDATE("DPMOVINV",{"MOV_ASOTIP","MOV_FECHA","MOV_IVA","MOV_PRECIO","MOV_TOTAL","MOV_LISTA"},{"MIX",B->EMISION,16,nPrecio,nPrecio,"A"},"MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND MOV_DOCUME"+GetWhere("=",cNumero))

     ENDIF

     SELECT B
   
     SKIP 

     IF nContar>5
     //   EXIT
     ENDIF

  ENDDO

  SQLUPDATE("DPCLIENTES","CLI_CODMON","DBC")

  ? LSTR(nContar)+" Registros Migrados en "+LSTR(ABS(SECONDS()-nT1)/60)+" Minutos"

  oTable:EXECUTE(" UPDATE dpdoccli    SET DOC_BASNET=DOC_NETO-DOC_MTOIVA WHERE DOC_TIPDOC"+GetWhere("=","CUO"))

  cSql:=[UPDATE DPDOCCLI SET DOC_VALCAM=IF(DOC_VALCAM=0,1,DOC_VALCAM),DOC_MTODIV=IF(DOC_DIVISA,DOC_NETO,ROUND(DOC_NETO/DOC_VALCAM,2)) WHERE DOC_TIPTRA="D" AND DOC_VALCAM<>1 ]
  oTable:EXECUTE(cSql)

  cSql:=[ UPDATE DPMOVINV ]+;
        [ INNER JOIN DPDOCCLI      ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND MOV_DOCUME=DOC_NUMERO AND DOC_TIPTRA='D'   AND DOC_VALCAM>0 ]+;
        [ SET MOV_MTODIV=ROUND(MOV_TOTAL/DOC_VALCAM,2), ]+;
        [ MOV_ASOTIP="MIX",MOV_IVA=16,MOV_PRECIO=DOC_BASNET,MOV_LISTA="A",MOV_FECHA=DOC_FECHA ]+;
        [ WHERE MOV_MTODIV=0 OR MOV_MTODIV=MOV_TOTAL OR MOV_MTODIV IS NULL ]

  oTable:Execute(cSql)

  // Asigna a todas las cuotas menor o igual al 10 de cada mes, como una cuota Penalizada
  // Evita penalizar cuotas penalizadas
  // 20/11/2023
  dFchIniMes:=FCHINIMES(oDp:dFecha)+10 
  cSql      :=[ UPDATE DPMOVINV ]+;
              [ SET MOV_X     =1 ]+;
              [ WHERE MOV_FECHA]+GetWhere("<=",dFchIniMes)

  oTable:Execute(cSql)

  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")
  oTable:End()

  SELECT B

  CLOSE ALL

  oMovInv:End()
 
RETURN .T.
// EOF
