// Programa   : DPRENCPA
// Fecha/Hora : 01/01/2018 02:34:15
// Propósito  : Importar compras desde Mixnet tabla 
// Creado Por : Juan Navas
// Llamado por: DPIMPRXLSRUN   
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodDef,lChk,lTodos,nCantid,oMemo,oMeterR,oSay,lBrowse)
   LOCAL cFileDbf,cFileXls,nLinIni
   LOCAL oMov,cGrupo,cMarca,cWhere,cLine,lOk,oEqui,cBarra,cMemoX:="",oSuc,oTable
   LOCAL aSelect:={},aCampos:={}
   LOCAL cField,nAt,n,aVar:={},cVar,cGruNombre:="",cMarNombre:="",oTable
   LOCAL cPrecio_A:="",cPrecio_B:="",cPrecio_C:="",cPrecio_D:="",cPrecio_E:="",cPrecio_L:=""
   LOCAL cUndMed:="",cPeso:="",cCXUNDMED:="",cPRESENTA:=""
   LOCAL cCANT  :="",cCOSTO:="",cLOTE:="",cFCHVENC:="",cCodSuc:="",cCodAlm:=""
   LOCAL cLIMSUC:="SI",cWhereS:="",oTabSuc
   LOCAL n_:=0,cMemo:="",cFileIxl:="",cTable,cCodigo,cTipo
   LOCAL aFields:={},aVars:={}
  

   DEFAULT lChk   :=.F.,;
           lTodos :=.F.,;
           nCantid:=1  ,;
           lBrowse:=.F.

//  AEVAL(OpenTable("SELECT * FROM DPPROVEEDOR",.F.):aFields,{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[Replace("]+a[1] })
// ? cMemo
// cMemo:=""

   DEFAULT cCodDef:=SQLGET("DPIMPRXLS","IXL_CODIGO")

   IIF(oSay=NIL,NIL,oSay:SetText("Leyendo Datos desde "+cFileDbf))

   CLOSE ALL

   cFileDbf:="C:\MOTORES\DPRENCPA.DBF" 

// ? FILE(cFileDbf)
   SELE A
   USE (cFileDbf) SHARED

   cMemo:=""
   AEVAL(DBSTRUCT(),{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[    oMov:Replace("MOV_XXXXXXX"]+",A->"+a[1]+") /"+"/"+a[2]+"("+LSTR(a[3])+")" })

   IF RECCOUNT()=0
      MensajeErr("No se realizó la Lectura de Registros, Revise Número de Línea de Lectura")
      CLOSE ALL
      RETURN .F.
   ENDIF

 
   IF lBrowse 
     BROWSE()
     CLOSE ALL
     RETURN NIL
   ENDIF

   IF Empty(ALIAS()) .AND. ValType(oMemo)="O"
      oMemo:Append("Archivo "+cFileDbf)
      RETURN .F.
   ENDIF

   aCampos:=ACLONE(DBSTRUCT())
   AEVAL(aCampos,{|a,n|aCampos[n]  :=ALLTRIM(a[1])})
   AEVAL(aSelect,{|a,n|aSelect[n,3]:=ALLTRIM(a[3])})

   SETEXCLUYE("DPMOVINV"  , "")

   SQLDELETE("DPMOVINV","MOV_USUARI"+GetWhere("=","MIX"))

   BROWSE()

   oMov :=OpenTable("SELECT * FROM DPMOVINV",.F.)

   WHILE !A->(EOF()) 

       IF Empty(A->ITEM) .AND.A->CANTIDAD<=0
           A->(DbSkip())
           LOOP
       ENDIF

CursorWait()

       IF A->(RECNO())%50=0
          MsgRun("Registro "+LSTR(RECNO())+"/"+LSTR(RECCOUNT()))
       ENDIF

      cLine  :=""

     // Asigna los Valores en el Objeto
      
//      AEVAL(aFields,{|a,n| oMov:Replace(a[2],A->(FIELDGET(a[3])))})
//     AEVAL(aVars  ,{|a,n| MOVER(A->(FIELDGET(a[3])),a[2])})

    cTipo:="E001"

    IF !ISSQLFIND("DPINV","INV_CODIGO"+GetWhere("=",A->ITEM))
       A->(DBSKIP())
       LOOP
    ENDIF

    oMov:AppendBlank()
    oMov:Replace("MOV_CODIGO" ,A->ITEM)    //C(15)
    oMov:Replace("MOV_FECHA"  ,A->EMISION) //D(8)
    oMov:Replace("MOV_HORA"   ,"00:00:00") //C(6)
    oMov:Replace("MOV_CODTRA" ,cTipo)    //C(2)
    oMov:Replace("MOV_TIPDOC" ,"FAC")     //C(2)

    oMov:Replace("MOV_DOCUME" ,A->NUMCOM) //C(10)
    oMov:Replace("MOV_UNDMED" ,"UND") // A->UNIDAD) //C(3)
//  oMov:Replace("MOV_XXXXXXX",A->REF_BULTO) //N(5)
    oMov:Replace("MOV_CANTID" ,A->CANTIDAD) //N(14)
    oMov:Replace("MOV_COSTO"  ,A->COSTO_TOT) //N(19)
    oMov:Replace("MOV_ORIGEN" ,"COM") //C(3)
    oMov:Replace("MOV_DESCUE" ,A->DESC  )
    oMov:Replace("MOV_CODCTA" ,A->PROVEE) //C(10)
    oMov:Replace("MOV_TOTAL"  ,A->COSTO_TOT) //N(17)
    oMov:Replace("MOV_APLORG" ,"C")
    oMov:Replace("MOV_CXUND",1)

    oMov:Replace("MOV_CODALM",oDp:cCodAlm)
    oMov:Replace("MOV_CODSUC",oDp:cSucursal)
    oMov:Replace("MOV_INVACT",1)
    oMov:Replace("MOV_FISICO",IF(LEFT(cTipo,1)="E",1,-1))
    oMov:Replace("MOV_LOGICO",IF(LEFT(cTipo,1)="E",1,-1))
    oMov:Replace("MOV_CONTAB",IF(LEFT(cTipo,1)="E",1,-1))
    oMov:Replace("MOV_METCOS","P")

     oMov:Replace("MOV_USUARI","MIX"  )  
     oMov:Commit()
      
     // Si esta en Revision, No agrega producto

     A->(DbSkip())

   ENDDO

   oMov:End()

   IF(oMemo=NIL,NIL,oMemo:Append(CRLF+"Proceso Concluido"))
 
   EJECUTAR("DPBUILDWHERE")

   CLOSE ALL
  
RETURN lOk

// EOF


